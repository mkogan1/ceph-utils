#include <stdio.h>
#include <stdlib.h>
#include <curl/curl.h>

char *my_method = "GET";
char *my_url = "https://acanthodes.eng.arb.redhat.com:35357/v3";

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

int doit()
{
	CURL *curl;
	CURLcode rc;
	char error_buf[CURL_ERROR_SIZE];
	long http_status;
	int r = 0;
	curl = curl_easy_init();
	if (!curl) {
		return 1;
	}
	curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, my_method);
	curl_easy_setopt(curl, CURLOPT_URL, my_url);
	curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 1L);
	curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
	curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, error_buf);
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, my_receive_http_data);
	rc = curl_easy_perform(curl);
	if (rc != CURLE_OK) {
		fprintf(stderr,"curl_easy_perform failed, %s\n",
			curl_easy_strerror(rc));
		r |= 2;
		goto Done;
	}
	curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_status);
Done:
	curl_easy_cleanup(curl);
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
	char *ap, *ep;
	int maxcount = 0;
	char *msg;
	int r;

	while (--ac > 0) if (*(ap = *++av) == '-') while (*++ap) switch(*ap) {
//	case 'v':
//		++vflag;
//		break;
	case '-':
		break;
	default:
	Usage:
		fprintf(stderr,"Usage: mkbig #times\n");
		exit(1);
	} else if (!maxcount) {
		maxcount = strtoll(ap, &ep, 0);
		if (!*ap) {
			msg = "empty";
		BadCount:
			fprintf(stderr,"bad maxcount <%s>?\n", msg);
			goto Usage;
		}
		if (!*ep)
			;
		else {
			msg = "nondigits after number";
			goto BadCount;
		}
	} else {
		fprintf(stderr,"extra arg?\n");
		goto Usage;
	}
	if (maxcount <= 0) {
		fprintf(stderr,"Missing maxcount\n");
		goto Usage;
	}
	curl_global_init(CURL_GLOBAL_DEFAULT);
	r = process(maxcount);
	curl_global_cleanup();
	exit(r);
}
