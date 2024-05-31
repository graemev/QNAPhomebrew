/* Break any backward dependency with hdparms.c */

/*------ try to break some unfortunate dependency on hdparm ------ */

extern int prefer_ata12;
extern int verbose;

/*---------------------------------------------------------------*/

extern void set_verbose     (int flag);
extern int  get_verbose     ();
extern void set_prefer_ata12(int flag);
extern int  get_prefer_ata12();

