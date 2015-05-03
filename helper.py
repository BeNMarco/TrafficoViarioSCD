#!/usr/bin/python
import argparse
import os
import shutil
import time
from subprocess import call, Popen, PIPE, STDOUT

script_dir = os.path.dirname(os.path.abspath(__file__))
configs_dir = "esempi_configurazione_quartieri"
exec_dir = "per_eseguire"
nameserver_dir = "name_server"
webserver_dir = "web_server"
centralserver_dir = "centralized_server"
prefix_quartiere = "quartiere_"
ior_file_path = os.path.join(script_dir,exec_dir,nameserver_dir,"ior.txt")

def list_config(nomi):
  for nome in nomi:
    files = os.walk(os.path.join(configs_dir,nome)).next()[2]
    ids = []
    for confFile in files:
      ids.append(confFile.replace('quartiere','').replace('.json',''))
    ids.sort()
    print " - " + nome + " (quartieri " + ",".join(ids)+")"

def setup_config(c):
  print "Preparazione della configurazione " + c
  files = os.walk(os.path.join(configs_dir,c)).next()[2]
  for confFile in files:
    id_quartiere = confFile.replace('quartiere','').replace('.json','')
    src_file = os.path.join(configs_dir,c,confFile)
    dest_file = os.path.join(exec_dir, prefix_quartiere+id_quartiere, "data" , "quartiere.json")
    print "copia di " + src_file + " in " + dest_file

    if not os.path.exists(os.path.dirname(dest_file)):
      os.makedirs(os.path.dirname(dest_file))
    shutil.copyfile(src_file, dest_file)

def get_nomi_configs():
  nomi =  os.walk(configs_dir).next()[1]
  return nomi

def configure(args):
  nomi_conf = get_nomi_configs()
  nomi_conf.sort()
  to_config = None

  if args.list:
    print "Le configurazioni disponibili sono le seguenti:"
    list_config(nomi_conf)

  if args.configurazione:
    to_config = args.configurazione

  if not args.list and not args.configurazione:
    print "=== Tool di configurazione ==="
    print "Questo comando permette di configurare la simulazione con un set di dati di esempio"
    print ""
    print "Le configurazioni disponibili sono le seguenti:"
    list_config(nomi_conf)
    print ""
    to_config = raw_input("Seleziona una configurazione: ")
    print ""

  if to_config is not None:
    if to_config in nomi_conf:
      setup_config(to_config)
    else:
      print "ATTENZIONE! Configurazione selezionata non presente"
      print "Le configurazioni disponibili sono le seguenti:"
      list_config(nomi_conf)

def get_nodi_quartiere():
  nodi = []
  dirs = os.walk(exec_dir).next()[1]
  for dirName in dirs:
    if dirName.startswith(prefix_quartiere):
      nodi.append(dirName.replace(prefix_quartiere,''))
  nodi.sort()
  return nodi

def print_info(args):
  print "=== Helper per l'avvio del progetto TrafficoViarioSCD ==="
  print "Questo comando restituisce informazioni riguardanti le"
  print "caratteristiche e le configuraizoni del sistema"
  print ""
  print "Nodi quartiere disponibili:"
  for nodo in get_nodi_quartiere():
    print " - "+nodo
  print ""
  print "Configurazioni disponibili:"
  configs = get_nomi_configs()
  configs.sort()
  list_config(configs)

def read_IOR():
  ior_file = open(ior_file_path,"r")
  ior = ior_file.read()
  ior_file.close()
  return ior

def check_start(args):
  good = True
  if not args.name_server and not args.IOR and not os.path.isfile(ior_file_path):
    good = False
    print "ATTENZIONE! IOR non recuperabile. Le cause sono le seguenti:"
    print " - File ior non presente"
    print " - Name server non avviato"
    print " - Nessuno ior specificato tramite il parametro -i (--IOR)"
    print ""

  if args.quartiere:
    q_avail = get_nodi_quartiere()
    for q in args.quartiere:
      if q not in q_avail:
        good = False
        print "ATTENZIONE! Il quartiere " + q + " non esiste."
    print ""

  return good

def count_ent(args):
  n = 0
  if args.name_server:
    n += 1

  if args.web_server:
    n += 1

  if args.centralized_server:
    n += 1

  if args.quartiere:
    n += len(args.quartiere)

  return n

def start(args):
  if check_start(args):
    sticky = True
    p = None
    n_to_start = 0

    if args.name_server:
      n_to_start += 1
      p = start_nameserver()
      time.sleep(1)

    # registrazione dello ior
    if args.IOR:
      os.environ['POLYORB_DSA_NAME_SERVICE'] = args.IOR
    else:
      os.environ['POLYORB_DSA_NAME_SERVICE'] = read_IOR()

    to_start = []

    # preparazione degli elementi a avviare
    if args.web_server:
      to_start.append([webserver_dir, "./webserver"])

    if args.centralized_server:
      to_start.append([centralserver_dir, "./server"])

    if args.quartiere:
      for q in args.quartiere:
        to_start.append([prefix_quartiere+q, "./local_quartiere"])

    n_to_start += len(to_start)

    if n_to_start > 1:
      sticky = False

    for el in to_start:
      w = start_nodo(el[0],el[1])
      if sticky:
        p = w

    if p:
      p.wait()

def start_nameserver():
  os.chdir(os.path.join(exec_dir, nameserver_dir))
  p = Popen('./nameserver')
  os.chdir(script_dir)
  return p

def start_webserver():
  os.chdir(os.path.join(exec_dir, webserver_dir))
  p = Popen('./webserver')
  os.chdir(script_dir)
  return p

def start_centralserver():
  os.chdir(os.path.join(exec_dir, centralserver_dir))
  p = Popen('./server')
  os.chdir(script_dir)
  return p

def start_quartiere(id_q):
  os.chdir(os.path.join(exec_dir, prefix_quartiere+id_q))
  p = Popen('./local_quartiere')
  os.chdir(script_dir)
  return p

def start_nodo(dir, eseguibile):
  os.chdir(os.path.join(exec_dir, dir))
  p = Popen(eseguibile)
  os.chdir(script_dir)
  return p


if __name__ == '__main__':
  parser = argparse.ArgumentParser(description="Tool di configurazione ed esecuzione TrafficoViarioSCD")
  subparsers = parser.add_subparsers(help="Help per le funzionalita'")

  parser_config = subparsers.add_parser('config', help='Configurazione e setup della simulazione')
  parser_config.set_defaults(func=configure)

  configgroup = parser_config.add_mutually_exclusive_group()
  parser_config.add_argument("-l", "--list", action='store_true', help="Elenca gli identificativi delle configurazioni disponibili")
  parser_config.add_argument("-c", "--configurazione", type=str, help="Seleziona la configurazione da utilizzare")

  parser_start = subparsers.add_parser('start', help='Avvio dei nodi della simulazione')
  parser_start.set_defaults(func=start)
  parser_start.add_argument("-i", "--IOR", type=str, help="Lo IOR da utilizzare per la registrazione con il name server")
  parser_start.add_argument("-ws", "--web-server", action='store_true', help="Avvia il web server")
  parser_start.add_argument("-ns", "--name-server", action='store_true', help="Avvia il name server")
  parser_start.add_argument("-cs", "--centralized-server", action='store_true', help="Avvia il server principale")
  parser_start.add_argument("-q", "--quartiere", type=str, nargs='+', help="Avvia i quartieri indicati. Per ottenere la lista dei quartieri disponibili usare il comando 'info'")
  parser_start.add_argument("-w", "--wait", action='store_true', help="Avvia il processo mantenendolo in foreground. Questa opzione viene ignorata se si avviano piu' entita' contemporaneamente. Se tra le entita' avviate vi e' il name server esso verra' avviato in foreground")

  parser_info = subparsers.add_parser('info', help='Informazioni riguardanti le caratteristiche del sistema e delle configurazioni')
  parser_info.set_defaults(func=print_info)
  
  args = parser.parse_args()
  print ""
  args.func(args)
