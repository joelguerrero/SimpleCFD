import numpy as np
import matplotlib.pyplot as plt

xc = np.fromfile('xc.dat', dtype = np.float64)
yc  = np.fromfile('yc.dat', dtype = np.float64)
divu = np.fromfile('divu_rt.dat', dtype = np.float64)

divu = divu.reshape(yc.size, xc.size)

plt.contourf(xc, yc, divu, 255,cmap=plt.cm.RdBu_r) 
#plt.imshow(divu, cmap=plt.cm.RdBu_r)
plt.grid(True)
plt.xlabel('x')
plt.ylabel('y') 
plt.title('divu')
plt.colorbar()
#plt.show()
plt.savefig('divu.png')
