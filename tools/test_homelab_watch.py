import unittest
from homelab_watch import unsafe

class MonitorLimits(unittest.TestCase):
    def test_limits_and_missing_sensors_fail_closed(self):
        normal={'cpu_c':60,'gpu_c':45,'available_mib':8000}
        self.assertFalse(unsafe(normal))
        for change in ({'cpu_c':75},{'gpu_c':75},{'available_mib':4095},
                       {'cpu_c':None},{'gpu_c':None}):
            self.assertTrue(unsafe({**normal,**change}))

if __name__=='__main__':unittest.main()
