


#!/usr/bin/python
import json
import sys

def main():

	ior_file = open("../name_server/ior.txt","r")
	ior = ior_file.read()
	ior_file.close()
	
	cfg_poly = open("first_polyorb","r")
	first_poly = cfg_poly.read()
	cfg_poly.close()

	cfg_poly = open("second_polyorb","r")
	second_poly = cfg_poly.read()
	cfg_poly.close()
	

	# Scrive un file.
	out_file = open("polyorb.conf","w")
	out_file.write(first_poly)
	out_file.write("name_service=" + ior)
	out_file.write(second_poly)
	out_file.close()

	


if __name__ == "__main__":
    main()
