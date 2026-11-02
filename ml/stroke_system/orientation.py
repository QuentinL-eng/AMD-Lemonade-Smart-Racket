"""Causal gravity tracking, matching the racket's Mahony correction gate.

Only gravity-relative quantities are used: accelerometer/gyro cannot observe
absolute court heading. The filter can be initialized from the live device pose.
"""
import math
import numpy as np


def gravity_body(t, accel, gyro):
    """World-up vector in sensor coordinates, after each sample."""
    output = np.zeros((len(t), 3))
    q0, q1, q2, q3 = 1., 0., 0., 0.
    ix, iy, iz = 0., 0., 0.
    initialized = False
    previous = float(t[0])
    for i in range(len(t)):
        ax, ay, az = (float(v) for v in accel[i])
        gx, gy, gz = (float(v) for v in gyro[i])
        an = math.sqrt(ax*ax+ay*ay+az*az)
        if not initialized and an > .5:
            ux, uy, uz = ax/an, ay/an, az/an
            if uz < -.999999:
                q0, q1, q2, q3 = 0., 1., 0., 0.
            else:
                norm = math.sqrt(2*(1+uz))
                q0, q1, q2, q3 = (1+uz)/norm, uy/norm, -ux/norm, 0.
            initialized = True
        dt = .001 if i == 0 else min(.02, max(.0002, float(t[i])-previous))
        previous = float(t[i])
        ux = 2*(q1*q3-q0*q2)
        uy = 2*(q2*q3+q0*q1)
        uz = 1-2*(q1*q1+q2*q2)
        if .85 < an < 1.15 and gx*gx+gy*gy+gz*gz < 9:
            ex, ey, ez = ay/an*uz-az/an*uy, az/an*ux-ax/an*uz, ax/an*uy-ay/an*ux
            ix += .05*ex*dt; iy += .05*ey*dt; iz += .05*ez*dt
            gx += 2*ex+ix; gy += 2*ey+iy; gz += 2*ez+iz
        speed = math.sqrt(gx*gx+gy*gy+gz*gz)
        if speed > 1e-9:
            angle = speed*dt/2
            s = math.sin(angle)/speed
            a, b, c, d = math.cos(angle), gx*s, gy*s, gz*s
            q0, q1, q2, q3 = (q0*a-q1*b-q2*c-q3*d, q0*b+q1*a+q2*d-q3*c,
                               q0*c-q1*d+q2*a+q3*b, q0*d+q1*c-q2*b+q3*a)
            norm = math.sqrt(q0*q0+q1*q1+q2*q2+q3*q3)
            q0 /= norm; q1 /= norm; q2 /= norm; q3 /= norm
        output[i] = [2*(q1*q3-q0*q2), 2*(q2*q3+q0*q1), 1-2*(q1*q1+q2*q2)]
    return output
