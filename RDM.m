function RDM(path, analyse, region)
    cond_list = ["v1", "v2", "v4"];
    load([path, char(cond_list(1)), '_when', char(region), '.mat']);
    
    
end