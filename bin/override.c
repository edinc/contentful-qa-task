#include <sys/types.h> 
#include <sys/socket.h> 
#include <netdb.h> 
#include <dlfcn.h> 
#include <stdio.h> 
#include <arpa/inet.h>
#include <stdlib.h> 
#include <string.h> 
#include <ctype.h> 

typedef struct {
  const char *host;
  const char *replacement;
} hosts_entry;

hosts_entry *hosts_array = NULL;
int num_elements = 0;
int num_allocated = 0;

char *trim(char *s)
{
  char *ptr;
  if (!s)
    return NULL;
  if (!*s)
    return s;
  for (ptr = s + strlen(s) - 1; (ptr >= s) && isspace(*ptr); --ptr);
  ptr[1] = '\0';
  return s;
}

//add entry to the hosts list
int add_host(hosts_entry entry)
{
  if (num_elements == num_allocated)
  { 
    if (num_allocated == 0)
      //allocate initially 30 elements
      num_allocated = 30;
    else
      num_allocated *= 2;

    void *_tmp = realloc(hosts_array, (num_allocated * sizeof(hosts_entry)));
    if (!_tmp)
    {
      fprintf(stderr, "ERROR: Couldn't realloc memory!\n");
      return(-1);
    }
    hosts_array = (hosts_entry*)_tmp;
  }

  hosts_array[num_elements] = entry;
  return ++num_elements;
}

int getaddrinfo(const char *node, const char *service,
    const struct addrinfo *hints, struct addrinfo **res) { 

  //pointer to original getaddrinfo() function
  static int (*libgetaddrinfo)(const char *node, const char *service,
      const struct addrinfo *hints, struct addrinfo **res); 

  int ret, i;
  const char *mynode = node;
  const char *tok, *replacement;
  const char *hosts_file;
  char buffer[1024];
  hosts_entry *entry;
  FILE *fp;
  //char ipstr[INET_ADDRSTRLEN];

  hosts_file = getenv("EXCLUDE_HOSTS_FILE");

  if (hosts_array == NULL && hosts_file != NULL) {
    if ((fp = fopen(hosts_file, "r")) != (FILE *)0) {
      while((fgets(buffer, 1024, fp)) != (char *)0 ) { 
        trim(buffer);
        //first token in a line is the ip address
        replacement = strtok(buffer, " ");
        //everything else is a host name
        tok = strtok (NULL, " ");
        while (tok != NULL)
        {
          entry = malloc(sizeof(hosts_entry));
          entry->host = strndup(tok, strlen(tok));
          entry->replacement = strndup(replacement, strlen(replacement));
          add_host(*entry);
          //printf("Fill \"%s\" with \"%s\"\n", entry->host, entry->replacement);
          tok = strtok (NULL, " ");
        }
      } 
    }
    fclose(fp);
  }

  for (i = 0; i < num_elements; i++) {
    //printf("Comparing %d _%s_ with _%s_\n", i, node, hosts_array[i].host);
    if (strcmp(node, hosts_array[i].host) == 0) {
      printf("Patching %s to %s\n", node, hosts_array[i].replacement);
      mynode = hosts_array[i].replacement;
      break;
    }
  }

  //bind to original getaddrinfo() symbol
  if (!libgetaddrinfo) { 
    void *handle; 
    char *error; 
    handle = dlopen("libc.so.6", RTLD_LAZY); 
    if (!handle) { 
      fputs(dlerror(), stderr); 
      exit(1); 
    } 
    libgetaddrinfo = dlsym(handle, "getaddrinfo"); 
    if ((error = dlerror()) != NULL) { 
      fprintf(stderr, "%s\n", error); 
      exit(1); 
    } 
  } 

  //call original getaddrinfo() and hand over our patched "node" (ip address)
  ret = libgetaddrinfo(mynode, service, hints, res); 

  /*
     inet_ntop(((struct addrinfo *)*res)->ai_addr->sa_family, 
     &((struct sockaddr_in*)((struct addrinfo *)*res)->ai_addr)->sin_addr, ipstr, sizeof(ipstr));
     printf("RESULT: %s\n", ipstr);
     */

  return ret;
} 

