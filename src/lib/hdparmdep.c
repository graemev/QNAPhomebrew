/* Break any backward dependency with hdparms.c */
#include "hdparmdep.h"

/*------ try to break some unfortunate dependency on hdparm ------ */

int prefer_ata12 = 0;
int verbose      = 0;

/*---------------------------------------------------------------*/

void set_verbose(int flag) {
  verbose=flag;
}

int get_verbose() {
  return(verbose);
}


void set_prefer_ata12(int flag) {
  prefer_ata12=flag;
}

int get_prefer_ata12() {
  return(prefer_ata12);
}
