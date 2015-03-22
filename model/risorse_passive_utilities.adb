with Text_IO;
with GNATCOLL.JSON;
with Ada.Strings.Unbounded;

with strade_e_incroci_common;
with data_quartiere;
with JSON_Helper;

use Text_IO;
use GNATCOLL.JSON;
use Ada.Strings.Unbounded;

use strade_e_incroci_common;
use data_quartiere;
use JSON_Helper;

package body risorse_passive_utilities is

   function create_array_abitanti(json_abitanti: JSON_array; json_autobus: JSON_array; from: Natural; to: Natural) return list_abitanti_quartiere is
      array_abitanti: list_abitanti_quartiere(from..to);
      residente: JSON_value;
      val_id_quartiere: Positive:= get_id_quartiere;
      val_id_luogo_casa: Positive;
      val_id_quartiere_luogo_lavoro: Natural;
      val_id_luogo_lavoro: Positive;
      mezzo: Ada.Strings.Unbounded.Unbounded_String;
      means: means_of_carrying;
      jolly: Boolean;
      jolly_to_quartiere: Natural;
   begin
      -- ciclo per inserimento abitanti(che non sono autobus)
      for index_residente in from..to-get_num_autobus loop
         residente:= Get(Arr => json_abitanti,Index => index_residente-from+1);
         val_id_luogo_casa:= Get(Val => residente, Field => "id_luogo_casa");
         val_id_quartiere_luogo_lavoro:= Get(Val => residente, Field => "id_quartiere_luogo_lavoro");
         val_id_luogo_lavoro:= Get(Val => residente, Field => "id_luogo_lavoro");
         mezzo:= Get(Val => residente, Field => "mezzo");
         if mezzo="walking" then
            means:= walking;
         elsif mezzo="bike" then
            means:= bike;
         else
            means:= car;
         end if;
         array_abitanti(index_residente):= create_abitante(id_abitante => index_residente, id_quartiere => val_id_quartiere,
                                                           id_luogo_casa => val_id_luogo_casa, id_quartiere_luogo_lavoro => val_id_quartiere_luogo_lavoro,
                                                           id_luogo_lavoro => val_id_luogo_lavoro,
                                                           mezzo => means,is_a_bus => False,jolly => False,jolly_to_quartiere => 0);
      end loop;
      -- ciclo per inserimento autobus
      for index_residente in to-get_num_autobus+1..to loop
         residente:= Get(Arr => json_autobus,Index => index_residente-(to-get_num_autobus));
         -- stazione_partenza:
         val_id_luogo_casa:= Get(Val => residente, Field => "stazione_partenza");
         val_id_quartiere_luogo_lavoro:= 0;
         -- linea
         val_id_luogo_lavoro:= Get(Val => residente, Field => "linea");
         -- jolly
         jolly:= Get(Val => residente, Field => "jolly");
         jolly_to_quartiere:= 0;
         if jolly then
            jolly_to_quartiere:= Get(Val => residente, Field => "jolly_to_quartiere");
         end if;
         means:= car;
         array_abitanti(index_residente):= create_abitante(id_abitante => index_residente, id_quartiere => val_id_quartiere,
                                                           id_luogo_casa => val_id_luogo_casa, id_quartiere_luogo_lavoro => val_id_quartiere_luogo_lavoro,
                                                           id_luogo_lavoro => val_id_luogo_lavoro,
                                                           mezzo => means,is_a_bus => True,jolly => jolly,jolly_to_quartiere => jolly_to_quartiere);

      end loop;
      return array_abitanti;
   end create_array_abitanti;

   function create_array_pedoni(json_pedoni: JSON_array; from: Natural; to: Natural) return list_pedoni_quartiere is
      array_pedoni: list_pedoni_quartiere(from..to-get_num_autobus);
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
      for index_residente in from..to-get_num_autobus loop
         residente:= Get(Arr => json_pedoni,Index => index_residente-from+1);
         val_id_abitante:= Get(Val => residente, Field => "id_abitante");
         if Has_Field(Val => residente, Field => "desired_velocity") then
            val_desired_velocity:= Get(Val => residente, Field => "desired_velocity");
         else
            val_desired_velocity:= Float(get_default_value_pedoni(value => desired_velocity));
         end if;
         if Has_Field(Val => residente, Field => "time_headway") then
            val_time_headway:= Get(Val => residente, Field => "time_headway");
         else
            val_time_headway:= Float(get_default_value_pedoni(value => time_headway));
         end if;
         if Has_Field(Val => residente, Field => "max_acceleration") then
            val_max_acceleration:= Get(Val => residente, Field => "max_acceleration");
         else
            val_max_acceleration:= Float(get_default_value_pedoni(value => max_acceleration));
         end if;
         if Has_Field(Val => residente, Field => "comfortable_deceleration") then
            val_comfortable_deceleration:= Get(Val => residente, Field => "comfortable_deceleration");
         else
            val_comfortable_deceleration:= Float(get_default_value_pedoni(value => comfortable_deceleration));
         end if;
         if Has_Field(Val => residente, Field => "s0") then
            val_s0:= Get(Val => residente, Field => "s0");
         else
            val_s0:= Float(get_default_value_pedoni(value => s0));
         end if;
         if Has_Field(Val => residente, Field => "length") then
            val_length:= Get(Val => residente, Field => "length");
         else
            val_length:= Float(get_default_value_pedoni(value => length));
         end if;
         array_pedoni(val_id_abitante+from-1):= create_pedone(id_abitante => val_id_abitante, id_quartiere => val_id_quartiere,
                                                              desired_velocity => val_desired_velocity, time_headway => val_time_headway,
                                                              max_acceleration => val_max_acceleration, comfortable_deceleration =>
                                                              val_comfortable_deceleration, s0 => val_s0, length => val_length);
      end loop;
      return array_pedoni;
   end create_array_pedoni;
   function create_array_bici(json_bici: JSON_array; from: Natural; to: Natural) return list_bici_quartiere is
      array_bici: list_bici_quartiere(from..to-get_num_autobus);
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
      for index_residente in from..to-get_num_autobus loop
         residente:= Get(Arr => json_bici,Index => index_residente-from+1);
         val_id_abitante:= Get(Val => residente, Field => "id_abitante");
         if Has_Field(Val => residente, Field => "desired_velocity") then
            val_desired_velocity:= Get(Val => residente, Field => "desired_velocity");
         else
            val_desired_velocity:= Float(get_default_value_bici(value => desired_velocity));
         end if;
         if Has_Field(Val => residente, Field => "time_headway") then
            val_time_headway:= Get(Val => residente, Field => "time_headway");
         else
            val_time_headway:= Float(get_default_value_bici(value => time_headway));
         end if;
         if Has_Field(Val => residente, Field => "max_acceleration") then
            val_max_acceleration:= Get(Val => residente, Field => "max_acceleration");
         else
            val_max_acceleration:= Float(get_default_value_bici(value => max_acceleration));
         end if;
         if Has_Field(Val => residente, Field => "comfortable_deceleration") then
            val_comfortable_deceleration:= Get(Val => residente, Field => "comfortable_deceleration");
         else
            val_comfortable_deceleration:= Float(get_default_value_bici(value => comfortable_deceleration));
         end if;
         if Has_Field(Val => residente, Field => "s0") then
            val_s0:= Get(Val => residente, Field => "s0");
         else
            val_s0:= Float(get_default_value_bici(value => s0));
         end if;
         if Has_Field(Val => residente, Field => "length") then
            val_length:= Get(Val => residente, Field => "length");
         else
            val_length:= Float(get_default_value_bici(value => length));
         end if;
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
      is_bus: Boolean;
   begin
      for index_residente in from..to loop
         if index_residente<=to-get_num_autobus then
            is_bus:= False;
         else
            is_bus:= True;
         end if;
         residente:= Get(Arr => json_auto,Index => index_residente-from+1);
         val_id_abitante:= Get(Val => residente, Field => "id_abitante");
         if Has_Field(Val => residente, Field => "desired_velocity") then
            val_desired_velocity:= Get(Val => residente, Field => "desired_velocity");
         else
            val_desired_velocity:= Float(get_default_value_auto(desired_velocity,is_bus));
         end if;
         if Has_Field(Val => residente, Field => "time_headway") then
            val_time_headway:= Get(Val => residente, Field => "time_headway");
         else
            val_time_headway:= Float(get_default_value_auto(time_headway,is_bus));
         end if;
         if Has_Field(Val => residente, Field => "max_acceleration") then
            val_max_acceleration:= Get(Val => residente, Field => "max_acceleration");
         else
            val_max_acceleration:= Float(get_default_value_auto(max_acceleration,is_bus));
         end if;
         if Has_Field(Val => residente, Field => "comfortable_deceleration") then
            val_comfortable_deceleration:= Get(Val => residente, Field => "comfortable_deceleration");
         else
            val_comfortable_deceleration:= Float(get_default_value_auto(comfortable_deceleration,is_bus));
         end if;
         if Has_Field(Val => residente, Field => "s0") then
            val_s0:= Get(Val => residente, Field => "s0");
         else
            val_s0:= Float(get_default_value_auto(s0,is_bus));
         end if;
         if Has_Field(Val => residente, Field => "length") then
            val_length:= Get(Val => residente, Field => "length");
         else
            val_length:= Float(get_default_value_auto(length,is_bus));
         end if;
         if Has_Field(Val => residente, Field => "num_posti") then
            val_num_posti:= Get(Val => residente, Field => "num_posti");
         else
            val_num_posti:=Positive(get_default_value_auto(num_posti,is_bus));
         end if;
         array_auto(val_id_abitante+from-1):= create_auto(id_abitante => val_id_abitante, id_quartiere => val_id_quartiere,
                                                              desired_velocity => val_desired_velocity, time_headway => val_time_headway,
                                                              max_acceleration => val_max_acceleration, comfortable_deceleration =>
                                                              val_comfortable_deceleration, s0 => val_s0, length => val_length, num_posti => val_num_posti);
      end loop;
      return array_auto;
   end create_array_auto;

end risorse_passive_utilities;
