# Resample data
import numpy as np
import netCDF4 as nc4
import matplotlib.pylab as plt
import scipy.ndimage

inpath = "I:/Data/NDVI/"


#%%
varname = ["Tair_f_inst","Qair_f_inst","Rainf_f_tavg"]
coords = np.array([-18,51,-35,38]) #[lonmin,lonmax,latmin,latmax]
dd = 0.5 # resolution
zoomin = 0.25/dd

xx, yy = np.meshgrid(np.arange(coords[0]+dd/2,coords[1]+dd/2,dd),np.arange(coords[2]+dd/2,coords[3]+dd/2,dd))
N = np.product(xx.shape)
xx1d = np.reshape(xx,[N,1])
yy1d = np.reshape(yy,[N,1])

for yr in range(2010,2017):
    for mon in range(1,13):
        A = np.concatenate([xx1d,yy1d,np.tile(yr,(N,1)),np.tile(mon,(N,1))],axis=1)
        fname  = "GLDAS_NOAH025_M.A"+str(yr)+str(mon).zfill(2)+".021.nc4"
        print(fname)
        D = nc4.Dataset(inpath+fname, 'r')
        lat = D.variables['lat']
        lon = D.variables['lon']

        for vid in range(len(varname)):
            var = D.variables[varname[vid]]
            z = np.reshape(var,[var.shape[1],var.shape[2]])
            idx = [i for i,em in enumerate(lon) if (em>coords[0] and em<coords[1])]
            idy = [i for i,em in enumerate(lat) if (em>coords[2] and em<coords[3])]
            zz = scipy.ndimage.zoom(z[min(idy):max(idy)+1,min(idx):max(idx)+1], zoomin, order=1)
            zz0 = scipy.ndimage.zoom(z[min(idy):max(idy)+1,min(idx):max(idx)+1], zoomin, order=0)
            zz1d = np.reshape(zz,[N,1])
            zz01d = np.reshape(zz0,[N,1])
            zz1d[zz1d<0]=zz01d[zz1d<0]
            A = np.concatenate([A,zz1d],axis=1)
        A1 = A[A[:,4]>0,]
#        with open('GLDAS.txt','ab') as f:
#            np.savetxt(f,A1,fmt=['%.2f','%.2f','%4d','%2d','%.2f','%.4f','%.8f'])



#%%
#zz.shape
#plt.imshow(zz)
#tt = scipy.ndimage.zoom(xv, 0.5, order=0)

#temp.shape
#plt.imshow(np.reshape(temp,[temp.shape[1],temp.shape[2]]))
#xv, yv = np.meshgrid(lon, lat)
##plt.imshow(xv);plt.colorbar()
##plt.imshow(yv);plt.colorbar()
#d0 = 0.25
#region = coords+np.array([1,1,1,1])*d0/2
#xx, yy = np.meshgrid(np.arange(region[0],region[1],d0),np.arange(region[2],region[3],d0))

#f = interpolate.interp2d(xx, yy, z, kind='linear')
