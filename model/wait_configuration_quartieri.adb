with Ada.Text_IO;

use Ada.Text_IO;

package body wait_configuration_quartieri is


   protected body wait_all_quartieri is
      procedure all_quartieri_set is
      begin
         Put_Line("ma ciao");
         segnale:= True;
      end all_quartieri_set;

      entry wait_quartieri when segnale=True is
      begin
         segnale:= False;
      end wait_quartieri;
   end wait_all_quartieri;



end wait_configuration_quartieri;
