#ifndef GEASS_MECH_HOST_H
#define GEASS_MECH_HOST_H
#include <stdint.h>
int64_t mechFileSize(const char *name);
int32_t mechFileRead(const char *name, uint8_t *out, int64_t count);
double mechScrollProgress(void);
double mechPageProgress(void);
void mechReady(void);
double mechNow(void);
void mechFetchStage(int32_t stage);
int32_t mechStageArrived(int32_t stage);
double mechTuned(const char *name, double low, double high, double preset);
#endif
