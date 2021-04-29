import folium
import pandas
from folium import plugins
from folium.plugins import HeatMap,HeatMapWithTime
import ray

its=["0324_032212","0324_032449","0324_032624"]
csvs = ["csv_total", "csv_time"]
dayno = ["1","2","5","20"]
numcpus = 14

centerlocsm = [38.73071198716413, -9.135256981966265]
index=[]
for hr in range(27):
    for b in [":00",":15",":30",":45"]:
        if hr < 10:
            index.append("0"+str(hr)+b)
        elif hr < 24:
            index.append(str(hr)+b)
        else:
            index.append("0"+str(hr-24)+b+" (+1 day)")

@ray.remote
def plottt(z):
    its, csv, daynum=z
    heatmapdatadst=[]      
    for i in range(1,109):
        try:
            genericwork1 = pandas.read_csv(f"iters/{its}/{csv}/day{daynum}/test"+str(i)+".csv")
            hr = []
            for j in range(len(genericwork1)):
                ww=genericwork1.iloc[j,2]
                if csv == "csv_time" and ww > 0.01:
                    hr.append( [genericwork1.iloc[j,0],genericwork1.iloc[j,1],ww ] )
                elif csv == "csv_total" and ww > 0.0:
                    hr.append( [genericwork1.iloc[j,0],genericwork1.iloc[j,1],ww ] )
            heatmapdatadst.append(hr)
        except:
            heatmapdatadst.append([])
    my_map = folium.Map(location=centerlocsm, zoom_start=14, prefer_canvas=True)
    HeatMapWithTime(heatmapdatadst,
                    min_opacity=0.2,radius=10,scale_radius=False,
                    index = index, use_local_extrema=False).add_to(my_map)
    my_map.save(f"iters/{its}/{csv}/day{daynum}.html")
    return 0

z=[]
for it in its:
    for csv in csvs: # "csv_time",
        for day in dayno:
            z.append((it,csv,day))
print(len(z))
ray.init(num_cpus=numcpus)  
a=ray.get([plottt.remote(z[i]) for i in range(len(z))])
ray.shutdown()

