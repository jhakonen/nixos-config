// Tämä ohjelma blokkaa suorituksen kunnes käyttäjä painaa paniketta joka on
// kytketty GPIO pinniin INPUT_PIN.

// Pohjautuu esimerkkiin http://abyz.me.uk/lg/EXAMPLES/lgpio/monitor.c

#include <lgpio.h>
#include <stdbool.h>
#include <stdio.h>

#define CHIP_ID 0
#define INPUT_PIN 3

// ============================================================================

static bool g_done = false;
void callback(int e, lgGpioAlert_p evt, void *data);

// ============================================================================

int main(int argc, char *argv[])
{
   // Hae kahva /dev/gpiochipX laitteeseen
   int handle = lgGpiochipOpen(CHIP_ID);
   if (handle < 0)
   {
      fprintf(stderr, "can't open gpiochip (%s)\n", lguErrorText(handle));
      return -1;
   }

   // Laitteen kahva saatu, avaa GPIO halytyksiä varten
   int err = lgGpioClaimAlert(handle, 0, LG_FALLING_EDGE, INPUT_PIN, -1);
   if (err < 0)
   {
      fprintf(stderr, "GPIO in use (%s)\n", lguErrorText(err));
      return -1;
   }

   // Kutsu callbackiä kun tulee hälytys
   lgGpioSetSamplesFunc(callback, NULL);

   // Odota kunnes painikkeen painallus on havaittu
   while (!g_done) lguSleep(1);

   return 0;
}

// ============================================================================

void callback(int e, lgGpioAlert_p evt, void *data)
{
   for (int i = 0; i < e; i++)
   {
      // Varmista että kyseeessä on haluttu painike
      if (evt[i].report.chip == CHIP_ID
          && evt[i].report.gpio == INPUT_PIN
          && evt[i].report.level == 0)
      {
         g_done = true;
      }
   }
}
