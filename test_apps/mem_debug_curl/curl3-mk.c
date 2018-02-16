// gcc -lcurl -g3 curl3.c -o curl3
// debuginfo-install curl nss openssl
// time valgrind --tool=massif --time-unit=B --max-snapshots=200 ./curl3

#include <stdio.h>
//#define CURL_STATICLIB
#include <curl/curl.h>

char *my_method = "GET";
//char *my_url = "https://acanthodes.eng.arb.redhat.com:35357/v3";
//char *my_url = "https://bugzilla.redhat.com";
//char *my_url = "https://google.com";    // url_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
//char *my_url = "https://google.co.il";
//char *my_url = "https://redhat.com";
//char *my_url = "http://www.worldofspectrum.org/";
//char *my_url = "https://duckduckgo.com/";
char *my_url = "https://localhost:4433";


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
	static CURL *curl = NULL;
	CURLcode rc;
	char error_buf[CURL_ERROR_SIZE];
	long http_status;
	int r = 0;
	if (!curl) {
        printf("curl_easy_init()\n");
		curl = curl_easy_init();
	}
	if (!curl) {
		return 1;
	}
	curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, my_method);
	curl_easy_setopt(curl, CURLOPT_URL, my_url);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
	curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 1L);
	curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
	curl_easy_setopt(curl, CURLOPT_ERRORBUFFER, error_buf);
	curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, my_receive_http_data);
	//curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
    curl_easy_setopt(curl, CURLOPT_CAINFO, "./server.crt");
	rc = curl_easy_perform(curl);
	if (rc != CURLE_OK) {
		fprintf(stderr,"curl_easy_perform failed, %s\n",
            curl_easy_strerror(rc));
		r |= 2;
        //curl_easy_reset(curl);
		goto Done;
	}
	curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &http_status);
Done:
        //curl_easy_reset(curl);
        //curl_easy_cleanup(curl);
	return r;
}

int process()
{
    int r = 0;
    int i;
    printf("processing\n");
    for (i = 0; i < 4096; ++i) {
        printf("."); fflush(stdout);
        r |= doit();
    }
    printf("\n");
    return r;
}

int main(int ac, char **av)
{
	int r;
	curl_global_init(CURL_GLOBAL_DEFAULT);
	r = process();
	curl_global_cleanup();
	return r;
}
