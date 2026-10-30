// Gyro full-scale probe: which CTRL6 codes really change the LSM6DSV320X's range?
//
// Firmware 1.5-1.7 wrote CTRL6 = 0x05 (+-4000 dps per ST's driver) and the rates still came out 2x high, with the
// same at-rest noise in raw counts as at +-2000. This sweeps FS_G codes (and two gyro ODRs) on the real chip with
// the racket held still, and prints the at-rest noise in raw LSB for each. At or below +-2000 dps the noise
// is a few LSB and rises as the range shrinks; a real step to a coarser range cuts it, so a code that really selects
// +-4000 dps shows a clearly lower count than +-2000.
//
// Keep the racket completely still while it runs (about 20 s, repeats). Output on the USB serial at 115200:
//   FS 0x05 ODR 0x0A readback 0x05  noise LSB x y z  mean LSB x y z  n
// Flashed with: pio run -e gyrofs -t upload
#include <Arduino.h>
#include <Wire.h>

static const int PIN_SDA = D4, PIN_SCL = D5;
static const uint8_t ADDR = 0x6A, ID = 0x73;
static const uint8_t WHO = 0x0F, CTRL1 = 0x10, CTRL2 = 0x11, CTRL3 = 0x12, CTRL6 = 0x15, CTRL8 = 0x17,
                     REG_STATUS = 0x1E, OUTX_L_G = 0x22;

static bool wr(uint8_t reg, uint8_t v) {
  Wire.beginTransmission(ADDR);
  Wire.write(reg);
  Wire.write(v);
  return Wire.endTransmission() == 0;
}

static bool rd(uint8_t reg, uint8_t *buf, size_t n) {
  Wire.beginTransmission(ADDR);
  Wire.write(reg);
  if (Wire.endTransmission(false) != 0) return false;
  if (Wire.requestFrom(ADDR, (uint8_t)n) != n) return false;
  for (size_t i = 0; i < n; i++) buf[i] = Wire.read();
  return true;
}

static uint8_t rd1(uint8_t reg) {
  uint8_t v = 0;
  rd(reg, &v, 1);
  return v;
}

static void probe(uint8_t fs, uint8_t odr) {
  wr(CTRL2, 0x00);                 // gyro power-down: the full scale may only change here (ST driver)
  delay(30);
  wr(CTRL6, fs);                   // LPF1 off, FS_G = code
  delay(5);
  uint8_t back = rd1(CTRL6);
  wr(CTRL2, odr);
  delay(200);                      // settle
  const int N = 1500;
  double sum[3] = {0, 0, 0}, dsq[3] = {0, 0, 0};
  int16_t prev[3] = {0, 0, 0};
  int n = 0;
  uint32_t t0 = millis();
  while (n < N && millis() - t0 < 4000) {
    if (!(rd1(REG_STATUS) & 0x02)) continue;   // GDA: new gyro sample
    uint8_t b[6];
    if (!rd(OUTX_L_G, b, 6)) continue;
    int16_t g[3] = {(int16_t)(b[1] << 8 | b[0]), (int16_t)(b[3] << 8 | b[2]), (int16_t)(b[5] << 8 | b[4])};
    for (int k = 0; k < 3; k++) {
      sum[k] += g[k];
      if (n > 0) dsq[k] += (double)(g[k] - prev[k]) * (g[k] - prev[k]);
      prev[k] = g[k];
    }
    n++;
  }
  Serial.printf("FS 0x%02X ODR 0x%02X readback 0x%02X  noise LSB %.2f %.2f %.2f  mean LSB %.1f %.1f %.1f  n %d\n", fs, odr,
                back, n > 1 ? sqrt(dsq[0] / (n - 1) / 2) : 0, n > 1 ? sqrt(dsq[1] / (n - 1) / 2) : 0,
                n > 1 ? sqrt(dsq[2] / (n - 1) / 2) : 0, n ? sum[0] / n : 0, n ? sum[1] / n : 0, n ? sum[2] / n : 0, n);
}

void setup() {
  Serial.begin(115200);
  delay(2500);
  Wire.begin(PIN_SDA, PIN_SCL);
  Wire.setClock(400000);
  Serial.printf("gyrofs probe. WHO_AM_I 0x%02X (expect 0x%02X). Keep the racket still.\n", rd1(WHO), ID);
  wr(CTRL3, 0x01);                 // software reset
  delay(20);
  wr(CTRL3, 0x44);                 // BDU + auto-increment
  wr(CTRL8, 0x03);                 // accel +-16 g
  wr(CTRL1, 0x0A);                 // accel 1.92 kHz high-performance, as production
}

// Tilt calibration: for each FS code, integrate the gyro between two still poses and compare with the angle the
// accelerometer (gravity) says the racket turned. With the true sensitivity unknown, the ratio gives it:
//   true mdps/LSB = assumed * accel_angle / gyro_angle.
// Do pure tilts (flat <-> tip-up, about 90 deg) holding each pose still for 2 s. Each mode runs 45 s.
struct Mode { uint8_t fs; float assumed_mdps; };
static const Mode MODES[] = {{0x04, 70.0f}, {0x0C, 140.0f}, {0x0D, 280.0f}};

static void runMode(const Mode &m) {
  wr(CTRL2, 0x00);
  delay(30);
  wr(CTRL6, m.fs);
  wr(CTRL2, 0x0A);
  delay(300);
  {
    double ga[3] = {0, 0, 0};
    int n = 0;
    uint32_t t0 = millis();
    while (n < 400 && millis() - t0 < 3000) {
      if (!(rd1(REG_STATUS) & 0x01)) continue;
      uint8_t a[6];
      if (!rd(0x28, a, 6)) continue;
      for (int k = 0; k < 3; k++) ga[k] += (int16_t)(a[2 * k + 1] << 8 | a[2 * k]) * 0.488e-3;
      n++;
    }
    if (n) Serial.printf("GRAVITY g (sensor x y z): %.3f %.3f %.3f  |g| %.3f\n", ga[0] / n, ga[1] / n, ga[2] / n,
                         sqrt(ga[0] * ga[0] + ga[1] * ga[1] + ga[2] * ga[2]) / n);
  }
  Serial.printf("MODE FS 0x%02X (assumed %.0f mdps/LSB, readback 0x%02X): tilt the racket flat <-> tip-up now\n", m.fs,
                m.assumed_mdps, rd1(CTRL6));
  float gAvg[3] = {0, 0, 1}, gStill[3] = {0, 0, 0};
  bool haveStill = false, reported = false;
  double pathDeg = 0;      // gyro path since the last still pose, using the assumed scale
  float bias[3] = {0, 0, 0}, biasAcc[3] = {0, 0, 0};
  int biasN = 0;
  uint32_t stillSince = 0, tPrev = micros(), tEnd = millis() + 45000;
  while (millis() < tEnd) {
    if (!(rd1(REG_STATUS) & 0x03)) continue;      // need gyro and accel
    uint8_t b[6], a[6];
    if (!rd(OUTX_L_G, b, 6) || !rd(0x28, a, 6)) continue;
    uint32_t t = micros();
    float dt = (t - tPrev) * 1e-6f;
    tPrev = t;
    float w[3], acc[3];
    for (int k = 0; k < 3; k++) {
      w[k] = (int16_t)(b[2 * k + 1] << 8 | b[2 * k]) * m.assumed_mdps * 1e-3f;                 // dps
      acc[k] = (int16_t)(a[2 * k + 1] << 8 | a[2 * k]) * 0.488e-3f;                              // g
      gAvg[k] += 0.02f * (acc[k] - gAvg[k]);
    }
    float wn = sqrtf((w[0] - bias[0]) * (w[0] - bias[0]) + (w[1] - bias[1]) * (w[1] - bias[1]) + (w[2] - bias[2]) * (w[2] - bias[2]));
    float an = sqrtf(acc[0] * acc[0] + acc[1] * acc[1] + acc[2] * acc[2]);
    bool still = wn < 3.0f && fabsf(an - 1.0f) < 0.03f;
    if (!still) {
      pathDeg += wn * dt;
      stillSince = 0;
      reported = false;
      biasN = 0;
      biasAcc[0] = biasAcc[1] = biasAcc[2] = 0;
      continue;
    }
    if (!stillSince) stillSince = millis();
    for (int k = 0; k < 3; k++) biasAcc[k] += w[k];
    biasN++;
    if (!reported && millis() - stillSince > 1500) {   // a settled still pose, handled once
      for (int k = 0; k < 3; k++) bias[k] = biasAcc[k] / biasN;
      float gn = sqrtf(gAvg[0] * gAvg[0] + gAvg[1] * gAvg[1] + gAvg[2] * gAvg[2]);
      float g[3] = {gAvg[0] / gn, gAvg[1] / gn, gAvg[2] / gn};
      Serial.printf("  STILL g (sensor x y z): %.3f %.3f %.3f\n", g[0], g[1], g[2]);
      if (haveStill) {
        float c = g[0] * gStill[0] + g[1] * gStill[1] + g[2] * gStill[2];
        float accelDeg = acosf(fmaxf(-1.0f, fminf(1.0f, c))) * 180.0f / (float)M_PI;
        if (accelDeg > 40.0f && pathDeg > 10.0f)
          Serial.printf("  tilt: accel %.1f deg, gyro path %.1f deg at assumed scale -> true %.1f mdps/LSB\n", accelDeg, pathDeg,
                        m.assumed_mdps * accelDeg / pathDeg);
      }
      for (int k = 0; k < 3; k++) gStill[k] = g[k];
      haveStill = true;
      pathDeg = 0;
      reported = true;                                 // do not re-trigger until motion resumes
    }
  }
}

void loop() {
  for (const Mode &m : MODES) runMode(m);
  Serial.println("DONE sweep (repeating)");
}
