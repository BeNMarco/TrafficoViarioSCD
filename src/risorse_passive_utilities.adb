with Text_IO;
with GNATCOLL.JSON;

with strade_e_incroci_common;
with data_quartiere;
with JSON_Helper;

use Text_IO;
use GNATCOLL.JSON;

use strade_e_incroci_common;
use data_quartiere;
use JSON_Helper;

package body risorse_passive_utilities is

   function create_array_abitanti(json_abitanti: JSON_array; from: Natural; to: Natural) return list_abitanti_quartiere is
      array_abitanti: list_abitanti_quartiere(from..to);
      residente: JSON_value;
      val_id_quartiere: Positive:= get_id_quartiere;
      val_id_luogo_casa: Positive;
      val_id_quartiere_luogo_lavoro: Positive;
      val_id_luogo_lavoro: Positive;
   begin
      for index_residente in from..to loop
         residente:= Get(Arr => json_abitanti,Index => index_residente-from+1);
         val_id_luogo_casa:= Get(Val => residente, Field => "id_luogo_casa");
         val_id_quartiere_luogo_lavoro:= Get(Val => residente, Field => "id_quartiere_luogo_lavoro");
         val_id_luogo_lavoro:= Get(Val => residente, Field => "id_luogo_lavoro");
         array_abitanti(index_residente):= create_abitante(id_abitante => index_residente, id_quartiere => val_id_quartiere,
                                                           id_luogo_casa => val_id_luogo_casa, id_quartiere_luogo_lavoro => val_id_quartiere_luogo_lavoro,
                                                           id_luogo_lavoro => val_id_luogo_lavoro);
      end loop;
      return array_abitanti;
   end create_array_abitanti;

   function create_array_pedoni(json_pedoni: JSON_array; from: Natural; to: Natural) return list_pedoni_quartiere is
      array_pedoni: list_pedoni_quartiere(from..to);
      residente: JSON_value;
      val_id_abitante: Positive;
      val_id_quartiere: Positive:= get_id_quartiere;
      val_desired_velocity: Float;
      val_time_headway: Float;
      val_max_acceleration: Float;
      val_comfortable_deceleration: Float;
      val_s0: Float;
      val_length: Float;
   begin
      for index_residente in from..to loop
         residente:= Get(Arr => json_pedoni,Index => index_residente-from+1);
         val_id_abitante:= Get(Val => residente, Field => "id_abitante");
         begin
            val_desired_velocity:= Get(Val => residente, Field => "desired_velocity");
         exception
            when others => val_desired_velocity:=get_default_value_pedoni(value => desired_velocity);
         end;
         begin
            val_time_headway:= Get(Val => residente, Field => "time_headway");
         exception
            when others => val_time_headway:=get_default_value_pedoni(value => time_headway);
         end;
         begin
         val_max_acceleration:= Get(Val => residente, Field => "max_acceleration");
         exception
            when others => val_max_acceleration:=get_default_value_pedoni(value => max_acceleration);
         end;
         begin
         val_comfortable_deceleration:= Get(Val => residente, Field => "comfortable_deceleration");
         exception
            when others => val_comfortable_deceleration:=get_default_value_pedoni(value => comfortable_deceleration);
         end;
         begin
         val_s0:= Get(Val => residente, Field => "s0");
         exception
            when others => val_s0:=get_default_value_pedoni(value => s0);
         end;
         begin
         val_length:= Get(Val => residente, Field => "length");
         exception
            when others => val_length:=get_default_value_pedoni(value => length);
         end;
         array_pedoni(val_id_abitante+from-1):= create_pedone(id_abitante => val_id_abitante, id_quartiere => val_id_quartiere,
                                                              desired_velocity => val_desired_velocity, time_headway => val_time_headway,
                                                              max_acceleration => val_max_acceleration, comfortable_deceleration =>
                                                              val_comfortable_deceleration, s0 => val_s0, length => val_length);
      end loop;
      return array_pedoni;
   end create_array_pedoni;
   function create_array_bici(json_bici: JSON_array; from: Natural; to: Natural) return list_bici_quartiere is
      array_bici: list_bici_quartiere(from..to);
      residente: JSON_value;
      val_id_abitante: Positive;
      val_id_quartiere: Positive:= get_id_quartiere;
      val_desired_velocity: Float;
      val_time_headway: Float;
      val_max_acceleration: Float;
      val_comfortable_deceleration: Float;
      val_s0: Float;
      val_length: Float;
   begin
      for index_residente in from..to loop
         residente:= Get(Arr => json_bici,Index => index_residente-from+1);
         val_id_abitante:= Get(Val => residente, Field => "id_abitante");
         begin
            val_desired_velocity:= Get(Val => residente, Field => "desired_velocity");
         exception
            when others => val_desired_velocity:=get_default_value_bici(value => desired_velocity);
         end;
         begin
            val_time_headway:= Get(Val => residente, Field => "time_headway");
         exception
            when others => val_time_headway:=get_default_value_bici(value => time_headway);
         end;
         begin
         val_max_acceleration:= Get(Val => residente, Field => "max_acceleration");
         exception
            when others => val_max_acceleration:=get_default_value_bici(value => max_acceleration);
         end;
         begin
         val_comfortable_deceleration:= Get(Val => residente, Field => "comfortable_deceleration");
         exception
            when others => val_comfortable_deceleration:=get_default_value_bici(value => comfortable_deceleration);
         end;
         begin
         val_s0:= Get(Val => residente, Field => "s0");
         exception
            when others => val_s0:=get_default_value_bici(value => s0);
         end;
         begin
         val_length:= Get(Val => residente, Field => "length");
         exception
            when others => val_length:=get_default_value_bici(value => length);
         end;
         array_bici(val_id_abitante+from-1):= create_bici(id_abitante => val_id_abitante, id_quartiere => val_id_quartiere,
                                                              desired_velocity => val_desired_velocity, time_headway => val_time_headway,
                                                              max_acceleration => val_max_acceleration, comfortable_deceleration =>
                                                              val_comfortable_deceleration, s0 => val_s0, length => val_length);
      end loop;
      return array_bici;
   end create_array_bici;

   function create_array_auto(json_auto: JSON_array; from: Natural; to: Natural) return list_auto_quartiere is
      array_auto: list_auto_quartiere(from..to);
      residente: JSON_value;
      val_id_abitante: Positive;
      val_id_quartiere: Positive:= get_id_quartiere;
      val_desired_velocity: Float;
      val_time_headway: Float;
      val_max_acceleration: Float;
      val_comfortable_deceleration: Float;
      val_s0: Float;
      val_length: Float;
      val_num_posti: Positive;
   begin
      for index_residente in from..to loop
         residente:= Get(Arr => json_auto,Index => index_residente-from+1);
         val_id_abitante:= Get(Val => residente, Field => "id_abitante");
         begin
            val_desired_velocity:= Get(Val => residente, Field => "desired_velocity");
         exception
            when others => val_desired_velocity:=get_default_value_auto(value => desired_velocity);
         end;
         begin
            val_time_headway:= Get(Val => residente, Field => "time_headway");
         exception
            when others => val_time_headway:=get_default_value_auto(value => time_headway);
         end;
         begin
         val_max_acceleration:= Get(Val => residente, Field => "max_acceleration");
         exception
            when others => val_max_acceleration:=get_default_value_auto(value => max_acceleration);
         end;
         begin
         val_comfortable_deceleration:= Get(Val => residente, Field => "comfortable_deceleration");
         exception
            when others => val_comfortable_deceleration:=get_default_value_auto(value => comfortable_deceleration);
         end;
         begin
         val_s0:= Get(Val => residente, Field => "s0");
         exception
            when others => val_s0:=get_default_value_auto(value => s0);
         end;
         begin
         val_length:= Get(Val => residente, Field => "length");
         exception
            when others => val_length:=get_default_value_auto(value => length);
         end;
         begin
         val_num_posti:= Get(Val => residente, Field => "num_posti");
         exception
            when others => val_num_posti:=Positive(get_default_value_auto(value => num_posti));
         end;
         array_auto(val_id_abitante+from-1):= create_auto(id_abitante => val_id_abitante, id_quartiere => val_id_quartiere,
                                                              desired_velocity => val_desired_velocity, time_headway => val_time_headway,
                                                              max_acceleration => val_max_acceleration, comfortable_deceleration =>
                                                              val_comfortable_deceleration, s0 => val_s0, length => val_length, num_posti => val_num_posti);
      end loop;
      return array_auto;
   end create_array_auto;

end risorse_passive_utilities;
