with Text_IO;

with strade_e_incroci_common;
with global_data;
with remote_types;

use Text_IO;

use strade_e_incroci_common;
use global_data;
use remote_types;

package body configuration_cache_abitanti is

   procedure registra_abitanti(from_id_quartiere: Positive; abitanti: list_abitanti_quartiere; pedoni: list_pedoni_quartiere;
                               bici: list_bici_quartiere; auto: list_auto_quartiere) is
   begin
      server_cache_abitanti.registra_abitanti(from_id_quartiere, abitanti, pedoni, bici, auto);
   end registra_abitanti;

   procedure get_bound_quartieri(bounds: out bound_quartieri) is
   begin
      server_cache_abitanti.get_bound_quartieri(bounds);
   end get_bound_quartieri;

   procedure cache_quartiere_creata is
   begin
      server_cache_abitanti.cache_quartiere_creata;
   end cache_quartiere_creata;

   function get_abitanti_quartieri return list_abitanti_temp is
   begin
      return server_cache_abitanti.get_abitanti_quartieri;
   end get_abitanti_quartieri;

   function get_pedoni_quartieri return list_pedoni_temp is
   begin
      return server_cache_abitanti.get_pedoni_quartieri;
   end get_pedoni_quartieri;

   function get_bici_quartieri return list_bici_temp is
   begin
      return server_cache_abitanti.get_bici_quartieri;
   end get_bici_quartieri;

   function get_auto_quartieri return list_auto_temp is
   begin
      return server_cache_abitanti.get_auto_quartieri;
   end get_auto_quartieri;

   function cfg_get_min_length_entità(entity: entità) return Float is
   begin
      return server_cache_abitanti.get_min_length_entità(entity);
   end cfg_get_min_length_entità;

   protected body cache_abitanti is

      procedure registra_abitanti(from_id_quartiere: Positive; abitanti: list_abitanti_quartiere; pedoni: list_pedoni_quartiere;
                                  bici: list_bici_quartiere; auto: list_auto_quartiere) is
      begin
         for i in pedoni'Range loop
            if pedoni(i).get_length_entità_passiva<min_length_pedoni then
               min_length_pedoni:= pedoni(i).get_length_entità_passiva;
            end if;
         end loop;
         for i in bici'Range loop
            if bici(i).get_length_entità_passiva<min_length_bici then
               min_length_bici:= bici(i).get_length_entità_passiva;
            end if;
         end loop;
         for i in auto'Range loop
            if auto(i).get_length_entità_passiva<min_length_auto then
               min_length_auto:= auto(i).get_length_entità_passiva;
            end if;
         end loop;

         temp_abitanti(from_id_quartiere):= new list_abitanti_quartiere'(abitanti);
         temp_pedoni(from_id_quartiere):= new list_pedoni_quartiere'(pedoni);
         temp_bici(from_id_quartiere):= new list_bici_quartiere'(bici);
         temp_auto(from_id_quartiere):= new list_auto_quartiere'(auto);
         quartieri_registrati:= quartieri_registrati + 1;
      end registra_abitanti;

      procedure get_bound_quartieri(bounds: out bound_quartieri) is
      begin
         for i in 1..get_num_quartieri loop
            bounds(i).from_abitanti:=temp_abitanti(i)'First;
            if bounds(i).from_abitanti<min_from_abitanti then
               min_from_abitanti:= bounds(i).from_abitanti;
            end if;
            bounds(i).to_abitanti:=temp_abitanti(i)'Last;
            if bounds(i).to_abitanti>max_to_abitanti then
               max_to_abitanti:= bounds(i).to_abitanti;
            end if;
         end loop;
      end get_bound_quartieri;

      procedure cache_quartiere_creata is
      begin
         abitanti_quartieri_registrati:= abitanti_quartieri_registrati+1;
         if abitanti_quartieri_registrati=get_num_quartieri then
            temp_abitanti:= null;
            temp_pedoni:= null;
            temp_bici:= null;
            temp_auto:= null;
         end if;
      end cache_quartiere_creata;

      function get_abitanti_quartieri return list_abitanti_temp is
         abitanti: list_abitanti_temp(1..get_num_quartieri,min_from_abitanti..max_to_abitanti);
      begin
         for i in 1..get_num_quartieri loop
            for j in temp_abitanti(i)'Range loop
               abitanti(i,j):= temp_abitanti(i)(j);
               --Put_Line("range" & Natural'Image(j));
            end loop;
         end loop;
         return abitanti;
      end get_abitanti_quartieri;

      function get_pedoni_quartieri return list_pedoni_temp is
         pedoni: list_pedoni_temp(1..get_num_quartieri,min_from_abitanti..max_to_abitanti);
      begin
         for i in 1..get_num_quartieri loop
            for j in temp_pedoni(i)'Range loop
               pedoni(i,j):= temp_pedoni(i)(j);
               --Put_Line("range" & Natural'Image(j));
            end loop;
         end loop;
         return pedoni;
      end get_pedoni_quartieri;

      function get_bici_quartieri return list_bici_temp is
         bici: list_bici_temp(1..get_num_quartieri,min_from_abitanti..max_to_abitanti);
      begin
         for i in 1..get_num_quartieri loop
            for j in temp_bici(i)'Range loop
               bici(i,j):= temp_bici(i)(j);
               --Put_Line("range" & Natural'Image(j));
            end loop;
         end loop;
         return bici;
      end get_bici_quartieri;

      function get_auto_quartieri return list_auto_temp is
         auto: list_auto_temp(1..get_num_quartieri,min_from_abitanti..max_to_abitanti);
      begin
         for i in 1..get_num_quartieri loop
            for j in temp_auto(i)'Range loop
               auto(i,j):= temp_auto(i)(j);
               --Put_Line("range" & Natural'Image(j));
            end loop;
         end loop;
         return auto;
      end get_auto_quartieri;

      function get_min_length_entità(entity: entità) return Float is
      begin
         case entity is
            when pedone_entity => return min_length_pedoni;
            when bici_entity => return min_length_bici;
            when auto_entity => return min_length_auto;
         end case;
      end get_min_length_entità;

   end cache_abitanti;

end configuration_cache_abitanti;
