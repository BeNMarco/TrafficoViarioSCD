package remote_types is
   pragma Remote_Types;

   -- begin gps
   type WebServer_Remote_Interface is limited interface;
   type Access_WebServer_Remote_Interface is access all WebServer_Remote_Interface'Class;

   procedure registra_mappa_quartiere(This: access WebServer_Remote_Interface; data: String; quartiere : Natural) is abstract;
   procedure invia_aggiornamento(This: access WebServer_Remote_Interface; data: String; quartiere : Natural) is abstract;

   --function calcola_percorso(obj: access gps_interface; from_id_quartiere: Positive; from_id_luogo: Positive;
   --                          to_id_quartiere: Positive; to_id_luogo: Positive) return route_and_distance is abstract;
   --function get_estremi_urbana(obj: access gps_interface; id_quartiere: Positive; id_urbana: Positive) return estremi_urbana is abstract;
   -- end gps

end remote_types;
