with Ada.Text_IO;

with numerical_types;
use numerical_types;

use Ada.Text_IO;

package body data_quartiere is

   function get_id_quartiere return Positive is
   begin
      return id_quartiere;
   end get_id_quartiere;
   function get_name_quartiere return String is
   begin
      return name_quartiere;
   end get_name_quartiere;
   function get_json_urbane return JSON_Array is
   begin
      return json_urbane;
   end get_json_urbane;
   function get_json_ingressi return JSON_Array is
   begin
      return json_ingressi;
   end get_json_ingressi;
   function get_json_incroci_a_4 return JSON_Array is
   begin
      return json_incroci_a_4;
   end get_json_incroci_a_4;
   function get_json_incroci_a_3 return JSON_Array is
   begin
      return json_incroci_a_3;
   end get_json_incroci_a_3;
   function get_json_rotonde_a_4 return JSON_Array is
   begin
      return json_rotonde_a_4;
   end get_json_rotonde_a_4;
   function get_json_rotonde_a_3 return JSON_Array is
   begin
      return json_rotonde_a_3;
   end get_json_rotonde_a_3;
   function get_json_traiettorie_incrocio return JSON_Value is
   begin
      return json_traiettorie_incrocio;
   end get_json_traiettorie_incrocio;
   function get_json_traiettorie_ingresso return JSON_Value is
   begin
      return json_traiettorie_ingresso;
   end get_json_traiettorie_ingresso;
   function get_json_traiettorie_cambio_corsie return JSON_Value is
   begin
      return json_traiettorie_cambio_corsie;
   end get_json_traiettorie_cambio_corsie;
   function get_json_road_parameters return JSON_Value is
   begin
      return json_road_parameters;
   end get_json_road_parameters;
   function get_json_quartiere return JSON_Value is
   begin
      return json_quartiere;
   end get_json_quartiere;

   function get_json_default_movement_entity return JSON_Value is
   begin
      return json_default_move_settings;
   end get_json_default_movement_entity;

   function get_from_urbane return Natural is
   begin
      return from_urbane;
   end get_from_urbane;
   function get_to_urbane return Natural is
   begin
      return to_urbane;
   end get_to_urbane;
   function get_from_ingressi return Natural is
   begin
      return from_ingressi;
   end get_from_ingressi;
   function get_to_ingressi return Natural is
   begin
      return to_ingressi;
   end get_to_ingressi;
   function get_from_incroci_a_4 return Natural is
   begin
      return from_incroci_a_4;
   end get_from_incroci_a_4;
   function get_to_incroci_a_4 return Natural is
   begin
      return to_incroci_a_4;
   end get_to_incroci_a_4;
   function get_from_incroci_a_3 return Natural is
   begin
      return from_incroci_a_3;
   end get_from_incroci_a_3;
   function get_to_incroci_a_3 return Natural is
   begin
      return to_incroci_a_3;
   end get_to_incroci_a_3;
   function get_from_incroci return Natural is
   begin
      if to_incroci_a_4/=0 then
         return get_from_incroci_a_4;
      else
         return get_from_incroci_a_3;
      end if;
   end get_from_incroci;
   function get_to_incroci return Natural is
   begin
      if to_incroci_a_3/=0 then
         return get_to_incroci_a_3;
      else
         return get_to_incroci_a_4;
      end if;
   end get_to_incroci;
   function get_from_rotonde_a_4 return Natural is
   begin
      return from_rotonde_a_4;
   end get_from_rotonde_a_4;
   function get_to_rotonde_a_4 return Natural is
   begin
      return to_rotonde_a_4;
   end get_to_rotonde_a_4;
   function get_from_rotonde_a_3 return Natural is
   begin
      return from_rotonde_a_3;
   end get_from_rotonde_a_3;
   function get_to_rotonde_a_3 return Natural is
   begin
      return to_rotonde_a_3;
   end get_to_rotonde_a_3;
   function get_json_pedoni return JSON_Array is
   begin
      return json_pedoni;
   end get_json_pedoni;
   function get_json_bici return JSON_Array is
   begin
      return json_bici;
   end get_json_bici;
   function get_json_auto return JSON_Array is
   begin
      return json_auto;
   end get_json_auto;
   function get_json_abitanti return JSON_Array is
   begin
      return json_abitanti;
   end get_json_abitanti;
   function get_from_abitanti return Natural is
   begin
      return from_abitanti;
   end get_from_abitanti;
   function get_to_abitanti return Natural is
   begin
      return to_abitanti;
   end get_to_abitanti;

   function get_num_abitanti return Natural is
   begin
      return size_json_abitanti;
   end get_num_abitanti;

   function get_num_task return Natural is
   begin
      return num_task;
   end get_num_task;

   function get_recovery return Boolean is
   begin
      return recovery;
   end get_recovery;

   function get_abilita_aggiornamenti_view return Boolean is
   begin
      return abilita_aggiornamenti_view;
   end get_abilita_aggiornamenti_view;

   protected body report_log is
      procedure configure is
      begin
         Create(Outfile, Out_File, abs_path & "data/log/" & name_quartiere & "_stallo.json");
         --Open(File => OutFile, Name => str_quartieri'Image(id_mappa) & "_log.txt", Mode => Append_File);
         Put_Line(OutFile, "{}");
         Close(OutFile);
      end configure;

      procedure write_state_stallo(id_quartiere: Positive; id_abitante: Positive; reset: Boolean) is
         state_stallo: JSON_Value:= Get_Json_Value(Json_String => "",Json_File_Name => abs_path & "data/log/" & name_quartiere & "_stallo.json");
      begin
         if id_quartiere=get_id_quartiere then
            if state_stallo.Has_Field(Positive'Image(id_abitante)) then
               if reset then
                  state_stallo.Set_Field(Positive'Image(id_abitante),state_stallo.Get(Positive'Image(id_abitante))+1);
               else
                  state_stallo.Set_Field(Positive'Image(id_abitante),0);
               end if;
            else
               if reset then
                  state_stallo.Set_Field(Positive'Image(id_abitante),1);
               else
                  state_stallo.Set_Field(Positive'Image(id_abitante),0);
               end if;
            end if;
            Open(File => OutFile, Name =>  abs_path & "data/log/" & name_quartiere & "_stallo.json", Mode => Out_File);
            Put_Line(OutFile, Write(state_stallo,False));
            Close(OutFile);
         else
            get_log_quartiere(id_quartiere).write_state_stallo(id_quartiere,id_abitante,reset);
         end if;
      end write_state_stallo;

      --procedure write(stringa: String) is
      --begin
      --   Open(File => OutFile, Name =>  abs_path & "data/log/" & name_quartiere & "_log.txt", Mode => Append_File);
      --   Put_Line(OutFile, stringa);
      --   Close(OutFile);
      --end write;

   end report_log;

   function get_log_stallo_quartiere return ptr_report_log is
   begin
      return my_log_stallo;
   end get_log_stallo_quartiere;

begin
   my_log_stallo.configure;
end data_quartiere;
