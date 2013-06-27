library(logging)

basicConfig(level="FINEST")
addHandler(writeToFile, file="log/project.log", level='DEBUG')