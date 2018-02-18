// time valgrind --tool=massif --time-unit=B --max-snapshots=200 ./curl5-mk01 -t 32 -m 8 1024 https://localhost:4433
// g++ -g3 -lcurl -lpthread -std=c++11 curl5-mk01.cc -o curl5-mk01

/*
building
rhel/centos nss:
yum install libcurl-devel
c++ -g -o curl5 curl5.cc -lcurl -lpthread -std=c++11

fedora nss:
dnf install libcurl-devel
c++ -g -o curl5 curl5.cc -lcurl -lpthread

ubuntu nss
as root,
apt-get install libcurl3-nss-dev
as self,
c++ -o curl5.nss -g curl5.cc -lcurl-nss -lpthread -std=c++11

ubuntu openssl
as root,
apt-get install libcurl4-openssl-dev
as self,
c++ -o curl5.ssl -g curl5.cc -lcurl -lpthread -std=c++11

ubuntu	gnutls
as root,
apt-get install libcurl4-gnutls-dev
as self,
c++ -o curl5.gnutls -g curl5.cc -lcurl-gnutls -lpthread -std=c++11
*/

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <atomic>
#include <vector>
#include <iostream>
#include <curl/curl.h>
#include <stdio.h>

const char *my_method = "GET";
const char *my_url;
const char *my_default_url = "https://acanthodes.eng.arb.redhat.com:35357/v3";
int multi_count;
int maxcount = 0;
int Vflag;
char *capath;

std::atomic_int easy_inits_made;
std::atomic_int reuses;
std::atomic_int reaps;
std::atomic_int carrier_allocs;
std::atomic_int carrier_frees;

pthread_mutex_t saved_mutex;
pthread_mutex_t time_mutex;

struct curl_carrier {
	int uses;
	struct timespec lastuse[1];
	CURL *h;
};
std::vector<curl_carrier *>saved_curl;

std::string
format_timespec(struct timespec *tv)
{
	char buf[512];
	snprintf(buf, sizeof buf, "%ld.%09ld", tv->tv_sec, tv->tv_nsec);
	return std::string(buf);
}

double timespec_to_float(struct timespec *tv)
{
	double r;
	r = tv->tv_nsec;
	r /= 1000000000;
	r += tv->tv_sec;
	return r;
}

struct curl_carrier *
get_curl_handle()
{
	struct curl_carrier *curl = 0;
	CURL *h;
	pthread_mutex_lock(&saved_mutex);
	if (!saved_curl.empty()) {
		curl = *saved_curl.begin();
		saved_curl.erase(saved_curl.begin());
		++reuses;
	}
	pthread_mutex_unlock(&saved_mutex);
	if (curl) {
	} else if ((h = curl_easy_init())) {
		++carrier_allocs;
		curl = new curl_carrier;
		curl->h = h;
		curl->uses = 0;
		++easy_inits_made;
	} else {
		// curl = 0;
	}
	return curl;
}

void
release_curl_handle_now(struct curl_carrier *curl)
{
	curl_easy_cleanup(curl->h);
	++carrier_frees;
	delete curl;
}

void
release_curl_handle(struct curl_carrier *curl)
{
	if (++curl->uses >= multi_count) {
		release_curl_handle_now(curl);
	} else {
		pthread_mutex_lock(&saved_mutex);
		clock_gettime(CLOCK_MONOTONIC_RAW, curl->lastuse);
		saved_curl.insert(saved_curl.begin(), 1, curl);
		pthread_mutex_unlock(&saved_mutex);
	}
}

int cleaner_shutdown;
pthread_t cleaner_id;
pthread_cond_t cleaner_cond;
#define MAXIDLE 5

void *curl_cleaner(void *h)
{
	struct curl_carrier *curl;
	struct timespec now[1];

	if (pthread_mutex_lock(&saved_mutex) < 0) {
		std::cerr << "lock failed " << errno << std::endl;
	}
	for (;;) {
		timespec until[1];
		if (cleaner_shutdown) {
			if (saved_curl.empty())
				break;
		} else {
			if (clock_gettime(CLOCK_REALTIME, now) < 0) {
				std::cerr << "gettime failed " << errno << std::endl;
			}
			now->tv_sec += MAXIDLE;
			if (pthread_cond_timedwait(&cleaner_cond, &saved_mutex, now) < 0) {
				std::cerr << "cond timedwait failed " << errno << std::endl;
			}
		}
		if (clock_gettime(CLOCK_MONOTONIC_RAW, now) < 0) {
			std::cerr << "gettime failed " << errno << std::endl;
		}
		while (!saved_curl.empty()) {
			auto cend = saved_curl.end();
			--cend;
			curl = *cend;
			saved_curl.erase(cend);
			if (!cleaner_shutdown && curl->lastuse->tv_sec
					>= now->tv_sec + MAXIDLE)
				break;
			if (!cleaner_shutdown)
				++reaps;
			release_curl_handle_now(curl);
		}
	}
	if (pthread_mutex_unlock(&saved_mutex) < 0) {
		std::cerr << "unlock failed " << errno << std::endl;
	}
}

void
init_curl_handles()
{
	pthread_create(&cleaner_id, nullptr, curl_cleaner, nullptr);
}

void
flush_curl_handles()
{
	struct curl_carrier *curl;
	void *result;

	cleaner_shutdown = 1;
	pthread_cond_signal(&cleaner_cond);
	if (pthread_join(cleaner_id, &result) < 0) {
		std::cerr << "pthread_join failed: " << errno << std::endl;
		return;
	}
	if (!saved_curl.empty()) {
		std::cerr << "cleaner failed final cleanup" << std::endl;
	}
	saved_curl.shrink_to_fit();
}

struct receiver_arg {
	int id;
	pthread_t me;
};

uint
my_receive_http_data(char *in, uint size, uint num, void *h)
{
	uint r;
	struct receiver_arg *z = (struct receiver_arg *) h;
	if (z->me != pthread_self())
	{
		std::cout << "oops: " << z->me << " != " << pthread_self() << std::endl;
		return 0;
	}
	r = size * num;
#if 0
	fprintf(stdout,"Received: ");
	r = fwrite(in, 1, r, stdout);
#endif
	return r;
}

void
timespec_diff(struct timespec *st, struct timespec *en)
{
	if (en->tv_nsec < st->tv_nsec) {
		en->tv_sec -= 1;
		en->tv_nsec += 1000000000;
	}
	en->tv_sec -= st->tv_sec;
	en->tv_nsec -= st->tv_nsec;
}

void
timespec_add(struct timespec *from, struct timespec *ac)
{
	ac->tv_sec += from->tv_sec;
	ac->tv_nsec += from->tv_nsec;
	if (ac->tv_nsec >= 1000000000) {
		ac->tv_sec += 1;
		ac->tv_nsec -= 1000000000;
	}
}

struct doit_stats {
	struct timespec first, rest;
	int first_count, rest_count;
};

int
doit(int id, struct doit_stats *ds)
{
	struct curl_carrier *ca;
	CURL *curl;
	CURLcode rc;
	char error_buf[CURL_ERROR_SIZE];
	long http_status;
	int r = 0;
	struct receiver_arg recvarg[1];
	recvarg->id = id;
	recvarg->me = pthread_self();
	struct timespec ts[2];

	ca = get_curl_handle();
	if (!ca)
		return 1;
	curl = ca->h;
	curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, my_method);
	curl_easy_setopt(curl, CURLOPT_URL, my_url);
	curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 1L);
	curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
	curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, error_buf);
	curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void*)recvarg);
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, my_receive_http_data);
    curl_easy_setopt(curl, CURLOPT_CAINFO, "./server.crt");
	if (Vflag) {
		curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
	}
	if (capath)
		curl_easy_setopt(curl, CURLOPT_CAINFO, capath);
	if (clock_gettime(CLOCK_MONOTONIC_RAW, ts) < 0) {
		std::cerr << "gettime failed " << errno << std::endl;
	}
	rc = curl_easy_perform(curl);
	if (clock_gettime(CLOCK_MONOTONIC_RAW, ts+1) < 0) {
		std::cerr << "gettime failed " << errno << std::endl;
	}
	timespec_diff(ts, ts+1);
	if (!ca->uses) {
		timespec_add(ts+1, &ds->first);
		++ds->first_count;
	} else {
		timespec_add(ts+1, &ds->rest);
		++ds->rest_count;
	}
	if (rc != CURLE_OK) {
		fprintf(stderr,"curl_easy_perform failed, %s\n",
			curl_easy_strerror(rc));
		r |= 2;
		goto Done;
	}
	curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_status);
Done:
	release_curl_handle(ca);
	return r;
}

std::atomic_int req_made;

struct doit_stats doit_results[1];

int
process()
{
	int r = 0;
	int i;
	struct doit_stats ds[1];
	ds->first_count = ds->rest_count = 0;
	ds->first.tv_sec = ds->first.tv_nsec = 0;
	ds->rest.tv_sec = ds->rest.tv_nsec = 0;
	for (;;) {
		i = req_made++;
		if (i >= maxcount) {
			break;
		}
		r |= doit(i, ds);
	}
	if (pthread_mutex_lock(&time_mutex) < 0) {
		std::cerr << "lock failed " << errno << std::endl;
	}
	doit_results->first_count += ds->first_count;
	doit_results->rest_count += ds->rest_count;
	timespec_add(&ds->first, &doit_results->first);
	timespec_add(&ds->rest, &doit_results->rest);
	if (pthread_mutex_unlock(&time_mutex) < 0) {
		std::cerr << "unlock failed " << errno << std::endl;
	}
	return r;
}

struct runner_arg {
	int number;
	int result;
};

void *
runner(void *_s)
{
	struct runner_arg *a = (struct runner_arg *) _s;
	a->result = process();
	return a;
}

struct runner_arg *ra;
pthread_t *runner_id;
int runner_count;

void
setup_runners(int nt)
{
	ra = new runner_arg[nt];
	runner_id = new pthread_t[nt];
	runner_count = nt;
}

void
start_runners()
{
	int i;

	for (i = 0; i < runner_count; ++i) {
		ra[i].number = i;
		pthread_create(runner_id + i, nullptr, runner, (void*)(ra + i));
	}
}

int
wait_for_runners()
{
	void *result;
	struct runner_arg *a;
	int i;
	int r = 0;

	for (i = 0; i < runner_count; ++i) {
		if (pthread_join(runner_id[i], &result) < 0) {
			std::cerr << "pthread_join failed: " << errno << std::endl;
			continue;
		}
		a = (struct runner_arg *) result;
		if (a->number != i) {
			std::cerr << "runner id changed? " << a->number << " != " << i << std::endl;
			continue;
		}
		r |= a->result;
	}
	return r;
}

void
release_runner_data()
{
	delete[] ra;
	delete[] runner_id;
	ra = nullptr;
	runner_id = nullptr;
}

int
main(int ac, char **av)
{
	char *ap, *ep, *cp;
	const char *msg;
	int r;
	int nt = 1;

	while (--ac > 0) if (*(ap = *++av) == '-') while (*++ap) switch(*ap) {
//	case 'v':
//		++vflag;
//		break;
	case '-':
		break;
	case 'C':
		if (ac < 1) {
			goto Usage;
		}
		--ac;
		capath = *++av;
		break;
	case 't':
		if (ac < 1) {
			goto Usage;
		}
		--ac;
		cp = *++av;
		nt = strtoll(cp, &ep, 0);
		if (cp == ep || *ep) {
			fprintf(stderr,"Bad threadcount <%s>\n", cp);
			goto Usage;
		}
		break;
	case 'V':
		++Vflag;
		break;
	case 'm':
		if (ac < 1) {
			goto Usage;
		}
		--ac;
		cp = *++av;
		multi_count = strtoll(cp, &ep, 0);
		if (cp == ep || *ep) {
			fprintf(stderr,"Bad multicount <%s>\n", cp);
			goto Usage;
		}
		break;
	default:
	Usage:
		fprintf(stderr,"Usage: curl5 [-t threads] [-m #m] #times url\n");
		exit(1);
	} else if (!maxcount) {
		maxcount = strtoll(ap, &ep, 0);
		if (!*ap) {
			msg = "empty";
		BadCount:
			fprintf(stderr,"bad maxcount <%s>: %s?\n", ap, msg);
			goto Usage;
		}
		if (!*ep)
			;
		else {
			msg = "nondigits after number";
			goto BadCount;
		}
	} else if (!my_url) {
		my_url = ap;
	} else {
		fprintf(stderr,"extra arg?\n");
		goto Usage;
	}
	if (maxcount <= 0) {
		fprintf(stderr,"Missing maxcount\n");
		goto Usage;
	}
	if (nt <= 0) {
		fprintf(stderr,"Invalid threadcount (-t)\n");
		goto Usage;
	}
	if (!my_url)
		my_url = getenv("MY_URL");
	if (!my_url)
		my_url = my_default_url;
	curl_global_init(CURL_GLOBAL_DEFAULT);
	init_curl_handles();
	setup_runners(nt);
	start_runners();
	r = wait_for_runners();
	release_runner_data();
	flush_curl_handles();
	curl_global_cleanup();
	std::cout << "curl_easy_init: " << easy_inits_made << std::endl;
	std::cout << "reuse curl: " << reuses << std::endl;
	std::cout << "timed-discard curl: " << reaps << std::endl;
	std::cout << "first: count=" << doit_results->first_count << " time=" <<
		format_timespec(&doit_results->first) << 
		" time-per=" << timespec_to_float(&doit_results->first)/doit_results->first_count << std::endl;
	std::cout << "rest: count=" << doit_results->rest_count << " time=" <<
		format_timespec(&doit_results->rest) << 
		" time-per=" << timespec_to_float(&doit_results->rest)/doit_results->rest_count << std::endl;
	std::cout << "alloc curl: " << carrier_allocs << std::endl;
	std::cout << "free curl: " << carrier_frees << std::endl;
	exit(r);
}

