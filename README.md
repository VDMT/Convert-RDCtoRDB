# Convert-RDCtoRDB

 Usage: .\Convert-RDCtoRDB "rdcman.rdg"
 
    This script will take as input a RDG (Remote Desktop Connection Manager)
     file and convert to a RDB (Remote Control) file.
     RDB is limited in that sub-groups are not available. Therefore all 
     sub-groups configured in a RDG file will be ignored, any hosts, will appear 
     under parent group
