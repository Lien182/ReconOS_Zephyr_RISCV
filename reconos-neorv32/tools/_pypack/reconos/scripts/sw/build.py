import reconos.utils.shutil2 as shutil2
import reconos.utils.template as template

import logging
import argparse
import subprocess

log = logging.getLogger(__name__)

def get_cmd(prj):
	return "build_sw"

def get_call(prj):
	return build_cmd

def get_parser(prj):
	parser = argparse.ArgumentParser("build_sw", description="""
		Builds the software project and generates an executable.
		""")
	return parser

def build_cmd(args):
	build(args)

def build(args):
	prj = args.prj
	swdir = prj.basedir + ".sw"
	if prj.impinfo.os == "zephyr":
		try:
			shutil2.chdir(swdir)
		except:
			log.error("software directory '" + swdir + "' not found")
			return
		subprocess.call("/usr/bin/cmake -Bbuild -G\"Unix Makefiles\" .", shell=True)
		try:
			shutil2.chdir("build")
		except:
			log.error("Build directory not found")
			return
		subprocess.call("make", shell=True)
		shutil2.copytree('zephyr/zephyr_exe.bin', swdir + '/' + prj.name + '_exe.bin')

	if prj.impinfo.os == "linux":
		try:
			shutil2.chdir(swdir)
		except:
			log.error("software directory '" + swdir + "' not found")
			return
		
		subprocess.call("make", shell=True)

	print()
	shutil2.chdir(prj.dir)