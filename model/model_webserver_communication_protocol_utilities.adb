with GNATCOLL.JSON;
with Ada.Text_IO;

with JSON_Helper;
with strade_e_incroci_common;
with data_quartiere;
with the_name_server;
with remote_types;
with global_data;
with risorse_passive_data;
with Ada.Strings.Unbounded;
with Ada.Characters.Handling;
with absolute_path;
with data_quartiere;
with Ada.Direct_IO;
with Ada.Directories;
with support_strade_incroci_common;

use data_quartiere;

use Ada.Characters.Handling;

use GNATCOLL.JSON;
use Ada.Text_IO;

use JSON_Helper;
use strade_e_incroci_common;
use data_quartiere;
use the_name_server;
use remote_types;
use global_data;
use risorse_passive_data;
use Ada.Strings.Unbounded;
use absolute_path;
use support_strade_incroci_common;


package body model_webserver_communication_protocol_utilities is

   procedure set_length_parameters_abitante(json: in out JSON_Value; mezzo: means_of_carrying; id_quartiere_abitante: Positive; id_abitante: Positive) is
   begin
      json.Set_Field("is_a_bus",get_quartiere_utilities_obj.get_abitante_quartiere(id_quartiere_abitante,id_abitante).is_a_bus);
      case mezzo is
         when car =>
            json.Set_Field("length_abitante",Float(get_quartiere_utilities_obj.get_auto_quartiere(id_quartiere_abitante,id_abitante).get_length_entità_passiva));
         when bike =>
            json.Set_Field("length_abitante",Float(get_quartiere_utilities_obj.get_bici_quartiere(id_quartiere_abitante,id_abitante).get_length_entità_passiva));
         when walking =>
            json.Set_Field("length_abitante",Float(get_quartiere_utilities_obj.get_pedone_quartiere(id_quartiere_abitante,id_abitante).get_length_entità_passiva));
      end case;
   end set_length_parameters_abitante;

   function create_entità_traiettoria_ingresso_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_urbana: Positive; id_urbana: Positive; where: new_float; polo: Boolean; where_ingresso: Float; traiettoria: traiettoria_ingressi_type; mezzo: means_of_carrying) return JSON_Value is
      json: JSON_Value:= Create_Object;
      length_car: Float;
   begin
      json.Set_Field("id_quartiere_abitante",id_quartiere_abitante);
      json.Set_Field("id_abitante",id_abitante);
      json.Set_Field("where","traiettoria_ingresso");
      json.Set_Field("id_quartiere_where",id_quartiere_urbana);
      json.Set_Field("id_where",id_urbana);
      json.Set_Field("distanza",Float(where));
      json.Set_Field("polo",polo);
      json.Set_Field("distanza_ingresso",where_ingresso);
      json.Set_Field("traiettoria",to_string_ingressi_type(traiettoria));
      json.Set_Field("mezzo",convert_means_to_string(mezzo));

      set_length_parameters_abitante(json,mezzo,id_quartiere_abitante,id_abitante);

      length_car:= Float(get_quartiere_utilities_obj.get_auto_quartiere(id_quartiere_abitante,id_abitante).get_length_entità_passiva)/2.0;
      if traiettoria=entrata_ritorno or else traiettoria=uscita_ritorno then
         if where=get_traiettoria_ingresso(traiettoria).get_intersezioni_corsie(linea_corsia).get_distanza_intersezioni_corsie then
            json.Set_Field("length_abitante",length_car);
         end if;
         if where=get_traiettoria_ingresso(traiettoria).get_intersezioni_corsie(linea_mezzaria).get_distanza_intersezioni_corsie then
            json.Set_Field("length_abitante",length_car);
         end if;
      end if;

      return json;
   end create_entità_traiettoria_ingresso_state;

   function create_car_traiettoria_cambio_corsia_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_urbana: Positive; id_urbana: Positive; where: Float; polo: Boolean; begin_overtaken: Float; from_corsia: Positive; to_corsia: Positive) return JSON_Value is
      json: JSON_Value:= Create_Object;
   begin
      json.Set_Field("id_quartiere_abitante",id_quartiere_abitante);
      json.Set_Field("id_abitante",id_abitante);
      json.Set_Field("where","cambio_corsia");
      json.Set_Field("id_quartiere_where",id_quartiere_urbana);
      json.Set_Field("id_where",id_urbana);
      json.Set_Field("distanza",where);
      json.Set_Field("polo",polo);
      json.Set_Field("distanza_inizio",begin_overtaken);
      json.Set_Field("corsia_inizio",from_corsia);
      json.Set_Field("corsia_fine",to_corsia);
      json.Set_Field("mezzo","car");

      set_length_parameters_abitante(json,car,id_quartiere_abitante,id_abitante);

      return json;
   end create_car_traiettoria_cambio_corsia_state;

   function create_entità_urbana_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_urbana: Positive; id_urbana: Positive; where: Float; polo: Boolean; corsia: Positive; mezzo: means_of_carrying) return JSON_Value is
      json: JSON_Value:= Create_Object;
   begin
      json.Set_Field("id_quartiere_abitante",id_quartiere_abitante);
      json.Set_Field("id_abitante",id_abitante);
      json.Set_Field("where","strada");
      json.Set_Field("id_quartiere_where",id_quartiere_urbana);
      json.Set_Field("id_where",id_urbana);
      json.Set_Field("distanza",where);
      json.Set_Field("polo",polo);
      json.Set_Field("corsia",corsia);
      json.Set_Field("mezzo",convert_means_to_string(mezzo));

      set_length_parameters_abitante(json,mezzo,id_quartiere_abitante,id_abitante);

      return json;
   end create_entità_urbana_state;

   function create_entità_ingresso_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_ingresso: Positive; id_ingresso: Positive; where: Float; polo: Boolean; mezzo: means_of_carrying) return JSON_Value is
      json: JSON_Value:= Create_Object;
   begin
      json.Set_Field("id_quartiere_abitante",id_quartiere_abitante);
      json.Set_Field("id_abitante",id_abitante);
      json.Set_Field("where","strada_ingresso");
      json.Set_Field("id_quartiere_where",id_quartiere_ingresso);
      json.Set_Field("id_where",id_ingresso);
      json.Set_Field("distanza",where);
      json.Set_Field("in_uscita",polo);
      case mezzo is
         when car =>
            json.Set_Field("corsia",1);
         when bike =>
            json.Set_Field("corsia",1);
         when walking =>
            json.Set_Field("corsia",2);
      end case;
      json.Set_Field("mezzo",convert_means_to_string(mezzo));

      set_length_parameters_abitante(json,mezzo,id_quartiere_abitante,id_abitante);

      return json;
   end create_entità_ingresso_state;

   function create_entità_incrocio_state(id_quartiere_abitante: Positive; id_abitante: Positive; id_quartiere_incrocio: Positive; id_incrocio: Positive; where: Float; id_quartiere_urbana_ingresso: Natural; id_urbana_ingresso: Natural; direzione: traiettoria_incroci_type; mezzo: means_of_carrying) return JSON_Value is
      json: JSON_Value:= Create_Object;
   begin

      json.Set_Field("id_quartiere_abitante",id_quartiere_abitante);
      json.Set_Field("id_abitante",id_abitante);
      json.Set_Field("where","incrocio");
      json.Set_Field("id_quartiere_where",id_quartiere_incrocio);
      json.Set_Field("id_where",id_incrocio);
      json.Set_Field("distanza",where);
      json.Set_Field("quartiere_strada_ingresso",id_quartiere_urbana_ingresso);
      json.Set_Field("strada_ingresso",id_urbana_ingresso);
      json.Set_Field("direzione",to_string_incroci_type(direzione));
      json.Set_Field("mezzo",convert_means_to_string(mezzo));

      set_length_parameters_abitante(json,mezzo,id_quartiere_abitante,id_abitante);

      return json;
   end create_entità_incrocio_state;

   function create_semafori_colori_state(id_quartiere_incrocio: Positive; id_incrocio: Positive; verso_semafori_verdi: Boolean; bipedi_can_cross: Boolean) return JSON_Value is
      json: JSON_Value:= Create_Object;
      json_arr_1: JSON_Array:= Empty_Array;
      json_arr_2: JSON_Array:= Empty_Array;
   begin
      json.Set_Field("id_quartiere_incrocio",id_quartiere_incrocio);
      json.Set_Field("id_incrocio",id_incrocio);
      json.Set_Field("abilitato_pedoni_bici",bipedi_can_cross);
      if bipedi_can_cross then
         Append(json_arr_1,Create(0));
         Append(json_arr_1,Create(1));
         Append(json_arr_1,Create(2));
         Append(json_arr_1,Create(3));
         json.Set_Field("index_road_rossi",json_arr_1);
         json.Set_Field("index_road_verdi",json_arr_2);
      else
         if verso_semafori_verdi then
            -- True => 1 e 3 verdi
            -- False => 2 e 4 verdi
            Append(json_arr_1,Create(1));
            Append(json_arr_1,Create(3));
            json.Set_Field("index_road_rossi",json_arr_1);
            Append(json_arr_2,Create(0));
            Append(json_arr_2,Create(2));
            json.Set_Field("index_road_verdi",json_arr_2);
         else
            Append(json_arr_1,Create(0));
            Append(json_arr_1,Create(2));
            json.Set_Field("index_road_rossi",json_arr_1);
            Append(json_arr_2,Create(1));
            Append(json_arr_2,Create(3));
            json.Set_Field("index_road_verdi",json_arr_2);
         end if;
      end if;
      return json;
   end create_semafori_colori_state;

   protected body state_view_quartiere is
      procedure registra_aggiornamento_stato_risorsa(id_risorsa: Positive; stato_abitanti: JSON_Array; stato_semafori: JSON_Value; stato_abitanti_uscenti: JSON_Array) is
         --json: JSON_Value;
      begin
         if get_abilita_aggiornamenti_view then
            num_task_updated:= num_task_updated+1;

            --Put_Line(Write(Create(stato_abitanti)));

            declare
               temp_str: String:= Write(Create(stato_abitanti));
            begin
               Open(File => tempFile, Name =>  abs_path & "data/temp_view/quartiere_abitanti.json", Mode => Append_File);

               if temp_str'Last>2 then
                  Put_Line(tempFile, temp_str(temp_str'First+1..temp_str'Last-1) & ",");
               end if;
               Close(tempFile);
            end;

            if stato_semafori=JSON_Null then
               null;
            else
               Open(File => tempFile, Name =>  abs_path & "data/temp_view/quartiere_semafori.json", Mode => Append_File);
               Put_Line(tempFile, Write(stato_semafori) & ",");
               Close(tempFile);
            end if;

            declare
               temp_str: String:= Write(Create(stato_abitanti_uscenti));
            begin
               Open(File => tempFile, Name =>  abs_path & "data/temp_view/quartiere_uscenti.json", Mode => Append_File);
               if temp_str'Last>2 then
                  Put_Line(tempFile, temp_str(temp_str'First+1..temp_str'Last-1) & ",");
               end if;
               Close(tempFile);
            end;

            --for i in 1..Length(stato_abitanti) loop
            --   Append(global_state_abitanti_quartiere,Get(stato_abitanti,i));
            --end loop;
            --Append(global_state_semafori_quartiere,stato_semafori);
            --for i in 1..Length(stato_abitanti_uscenti) loop
            --   Append(global_state_abitanti_quartiere_uscenti,Get(stato_abitanti_uscenti,i));
            --end loop;
            if num_task_updated=get_num_task then
               num_task_updated:= 0;
               --json:= Create_Object;
               --Put_Line(To_String(global_state_abitanti_quartiere_prova));
               declare
                  --str_1: String(1..Natural(Ada.Directories.Size(abs_path & "data/temp_view/" & get_name_quartiere & "_abitanti.json")));
                  len_1: Natural:= Natural(Ada.Directories.Size(abs_path & "data/temp_view/quartiere_abitanti.json"));
                  subtype File_String_1 is String (1 .. len_1);

                  package File_String_IO_1 is new Ada.Direct_IO (File_String_1);

                  file_1: File_String_IO_1.File_Type;
                  str_1: File_String_1;

                  len_2: Natural:= Natural(Ada.Directories.Size(abs_path & "data/temp_view/quartiere_semafori.json"));
                  subtype File_String_2 is String (1 .. len_2);

                  package File_String_IO_2 is new Ada.Direct_IO (File_String_2);

                  file_2: File_String_IO_2.File_Type;
                  str_2: File_String_2;

                  len_3: Natural:= Natural(Ada.Directories.Size(abs_path & "data/temp_view/quartiere_uscenti.json"));
                  subtype File_String_3 is String (1 .. len_3);

                  package File_String_IO_3 is new Ada.Direct_IO (File_String_3);

                  file_3: File_String_IO_3.File_Type;
                  str_3: File_String_3;



                  virgoletta: constant Character:= '"';
                  close_quadra: constant Character:= ']';
                  abit: constant String:= "{" & virgoletta & "abitanti" & virgoletta & ":[";
                  sem: constant String:= "," & virgoletta & "semafori" & virgoletta & ":[";
                  ab_usc: constant String:= "," & virgoletta & "abitanti_uscenti" & virgoletta & ":[";

                  output: String(1..len_1+len_2+len_3+abit'Length+sem'Length+ab_usc'Length+4); -- +4 per i caratteri di chiusura

                  posix: Natural:= 0;
               begin

                  output(output'First..abit'Length):= abit;

                  File_String_IO_1.Open(file => file_1, Name =>  abs_path & "data/temp_view/quartiere_abitanti.json", Mode => File_String_IO_1.In_File);

                  if len_1>1 then
                     File_String_IO_1.Read(file_1,str_1);
                     output(abit'Length+1..len_1+abit'Length-2):= str_1(1..len_1-2);
                     posix:= len_1+abit'Length-1;
                     output(posix):= ']';
                     posix:= posix+1;
                  else
                     output(abit'Length+1):= ']';
                     posix:= abit'Length+2;
                  end if;

                  --Put_Line(output);

                  File_String_IO_1.Close(file_1);

                  --Put_Line(Positive'Image(sem'Last));

                  output(posix..posix+sem'Last-1):= sem;
                  posix:= posix+sem'Length;

                  File_String_IO_2.Open(file => file_2, Name =>  abs_path & "data/temp_view/quartiere_semafori.json", Mode => File_String_IO_2.In_File);
                  if len_2>1 then
                     File_String_IO_2.Read(file_2,str_2);
                     output(posix..len_2+posix-2):= str_2(1..str_2'Last-1);
                     posix:= len_2+posix-2;
                     output(posix):= ']';
                     posix:= posix+1;
                  else
                     output(posix):= ']';
                     posix:= posix+1;
                  end if;

                  --Put_Line(output);

                  File_String_IO_2.Close(file_2);

                  output(posix..posix+ab_usc'Length-1):= ab_usc;
                  posix:= posix+ab_usc'Length;

                  File_String_IO_3.Open(file => file_3, Name =>  abs_path & "data/temp_view/quartiere_uscenti.json", Mode => File_String_IO_3.In_File);

                  if len_3>1 then
                     File_String_IO_3.Read(file_3,str_3);
                     output(posix..posix+len_3-2):= str_3(1..str_3'Last-1);
                     posix:= len_3+posix-2;
                     output(posix..posix+1):= "]}";
                     posix:= posix+1;
                  else
                     output(posix..posix+1):= "]}";
                     posix:= posix+1;
                  end if;

                  File_String_IO_3.Close(file_3);

                  --Put_Line(output(1..posix));

                  get_webServer.invia_aggiornamento(output(1..posix),get_id_quartiere);

                  --json.Set_Field("abitanti","[" & str_1 & "]");
               end;


               --json.Set_Field("abitanti","[" & str_1 & "]");
               --json.Set_Field("semafori",global_state_semafori_quartiere);
               --json.Set_Field("abitanti_uscenti",global_state_abitanti_quartiere_uscenti);
               --get_webServer.invia_aggiornamento(Write(json),get_id_quartiere);
               --global_state_abitanti_quartiere:= Empty_Array;
               --global_state_semafori_quartiere:= Empty_Array;
               --global_state_abitanti_quartiere_uscenti:= Empty_Array;
               Open(File => tempFile, Name =>  abs_path & "data/temp_view/quartiere_abitanti.json", Mode => Out_File);
               Put_Line(tempFile, "");
               Close(tempFile);

               Open(File => tempFile, Name =>  abs_path & "data/temp_view/quartiere_semafori.json", Mode => Out_File);
               Put_Line(tempFile, "");
               Close(tempFile);


               Open(File => tempFile, Name =>  abs_path & "data/temp_view/quartiere_uscenti.json", Mode => Out_File);
               Put_Line(tempFile, "");
               Close(tempFile);

            end if;
         end if;
      end registra_aggiornamento_stato_risorsa;
   end state_view_quartiere;

end model_webserver_communication_protocol_utilities;
