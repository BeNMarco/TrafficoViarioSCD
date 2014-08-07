with configuration_cache_abitanti;
with Text_IO;

use configuration_cache_abitanti;
use Text_IO;

package body resource_mappa_inventory is
   pragma Warnings(off);
   po:Positive;
   p:pedone;
begin

   pedoni(1,1):= p;
   po:=5;

   declare
      t:Natural:=po;
   begin
      t:=t+1;
   end;

pragma Warnings(on);
   --d.change(pedoni);
end resource_mappa_inventory;
