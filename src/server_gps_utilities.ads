with strade_e_incroci_common;
with remote_types;

use strade_e_incroci_common;
use remote_types;

package server_gps_utilities is

   num_quartieri: constant Positive:= 2; -- TO CHANGE WITH INPUT FROM FILE

   type index_incroci is tagged private;
   type estremi_incrocio is array(Positive range 1..2) of index_incroci;
   type hash_quartiere_strade is array(Positive range <>) of estremi_incrocio;
   type hash_quartieri_strade is array(Positive range <>) of access hash_quartiere_strade;

   type adiacente is tagged private;
   type list_adiacenti is array(Positive range 1..4) of adiacente;
   type nodi_quartiere is array(Positive range <>) of list_adiacenti;
   type grafo_mappa is array(Positive range <>) of access nodi_quartiere;

   function create_new_index_incrocio(val_id_quartiere: Positive; val_id_incrocio: Positive) return index_incroci;

   function create_new_adiacente(val_id_quartiere_strada: Natural; val_id_strada: Natural;
                                 val_id_quartiere_adiacente: Natural; val_id_adiacente: Natural) return adiacente;

   -- begin get methods index_incrocio
   function get_id_quartiere_index_incroci(incrocio: access index_incroci) return Positive;
   function get_id_incrocio_index_incroci(incrocio: access index_incroci) return Positive;
   -- end get methods index_incrocio

   -- begin get methods adiacente
   function get_id_quartiere_strada(near: access adiacente) return Natural;
   function get_id_strada(near: access adiacente) return Natural;
   function get_id_quartiere_adiacente(near: access adiacente) return Natural;
   function get_id_adiacente(near: access adiacente) return Natural;
   -- end get methods adiacente

   protected type registro_strade_resource is new gps_interface with
      procedure registra_urbane_quartiere(id_quartiere: Positive; urbane: strade_urbane_features);
      procedure registra_ingressi_quartiere(id_quartiere: Positive; ingressi: strade_ingresso_features);
      entry registra_incroci_quartiere(id_quartiere: Positive; incroci_a_4: list_incroci_a_4;
                                       incroci_a_3: list_incroci_a_3);
   private
      cache_urbane: urbane_quartiere(1..num_quartieri);
      cache_ingressi: ingressi_quartiere(1..num_quartieri);
      -- struttura inizializzata con la new in quanto poi può essere rimossa assegnando un puntatore nullo
      -- dato che rimanerre altrimenti nello scope.
      hash_urbane_quartieri: access hash_quartieri_strade:= new hash_quartieri_strade(1..num_quartieri);
      grafo: grafo_mappa(1..num_quartieri);
      num_urbane_quartieri_registrate: Natural:= 0;
      num_incroci_quartieri_registrati: Natural:= 0;
   end registro_strade_resource;

   type ptr_registro_strade_resource is access all registro_strade_resource;

private

   type index_incroci is tagged record
      id_quartiere: Natural:= 0;
      id_incrocio: Natural:= 0;
   end record;

   type adiacente is tagged record
      id_quartiere_strada: Natural:= 0;    -- se id_quartiere_strada e/o id_strada sono 0 significa che
      id_strada: Natural:= 0;		   -- non esiste l'adiacente;
      id_quartiere_adiacente: Natural:= 0; -- !!!!!! id_quartiere_adiacente e id_adiacente possono essere entrambi 0
      id_adiacente: Natural:= 0;           -- ma id_quartiere_strada e id_strada diversi da 0 sse la strada è una
   end record;				   -- strada chiusa.

end server_gps_utilities;
