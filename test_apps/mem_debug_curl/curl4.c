#include <stdio.h>
#include <stdlib.h>
#include <curl/curl.h>

char *my_method = "GET";
char *my_url;
char *my_default_url = "https://acanthodes.eng.arb.redhat.com:35357/v3";
int multi_count;
int Vflag;

uint
my_receive_http_data(char *in, uint size, uint num, void *h)
{
	uint r;
	r = size * num;
#if 0
	fprintf(stdout,"Received: ");
	r = fwrite(in, 1, r, stdout);
#endif
	return r;
}

CURL *saved_curl;
int save_until;
char *capath;

int doit()
{
	CURL *curl;
	CURLcode rc;
	char error_buf[CURL_ERROR_SIZE];
	long http_status;
	int r = 0;

	if ((curl = saved_curl)) {
	} else if ((curl = curl_easy_init())) {
		save_until = multi_count;
	} else {
		return 1;
	}
	curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, my_method);
	curl_easy_setopt(curl, CURLOPT_URL, my_url);
	curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 1L);
	curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
	curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, error_buf);
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, my_receive_http_data);
	if (Vflag) {
		curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
	}
	if (capath)
		curl_easy_setopt(curl, CURLOPT_CAINFO, capath);
	rc = curl_easy_perform(curl);
	if (rc != CURLE_OK) {
		fprintf(stderr,"curl_easy_perform failed, %s\n",
			curl_easy_strerror(rc));
		r |= 2;
		goto Done;
	}
	curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_status);
Done:
	if (--save_until < 1) {
		curl_easy_cleanup(curl);
		saved_curl = 0;
	} else {
		saved_curl = curl;
	}
	return r;
}

int process(int maxcount)
{
	int r = 0;
	int i;
	for (i = 0; i < maxcount; ++i)
		r |= doit();
	return r;
}

int main(int ac, char **av)
{
	char *ap, *ep, *cp;
	int maxcount = 0;
	char *msg;
	int r;

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
		fprintf(stderr,"Usage: mkbig [-m #m] #times url\n");
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
	if (!my_url)
		my_url = getenv("MY_URL");
	if (!my_url)
		my_url = my_default_url;
	curl_global_init(CURL_GLOBAL_DEFAULT);
	r = process(maxcount);
	if (saved_curl)
		curl_easy_cleanup(saved_curl);
	curl_global_cleanup();
	exit(r);
}
