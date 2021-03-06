/*

Javascript chain 

by Chunlong ( jszen.com ) 
longbill.cn@gmail.com


Example:

new JSChain(
{
  foo: function(next)
  {
    console.log('foo');
    setTimeout(next,1000);
  },
  bar: function(a,b,next)
  {
    console.log('bar: '+a+' '+b);
    setTimeout(next,1000);
  }
}).foo().bar('hello','world').exec(function(next)
{
  console.log('cumtome function');
  setTimeout(next,1000);
}).exec(function()
{
  console.log('done');
});


*/

function JSChain(obj)
{
  var self = this;
  this.____items = []; //this remembers the callback functions list
  this.____finally = null;
  this.____next = function(jump)  //execute next function
  {
    if (!jump)
    {
      var func = self.____items.shift();
      if (func) func.call();
    }
    else self.____items = [];
    
    if (self.____items.length == 0 && typeof self.____finally == 'function')
    {
      self.____finally.call(obj);
      self.____finally = null;
    }
  };

  this.exec = function() //support for custom function
  {
    var args = [].slice.call(arguments,1),func = arguments[0];
    args.push(self.____next);
    self.____items.push(function()
    {
      func.apply(obj,args);
    });
    return self;
  };

  this.end = function(func) //support for final function
  {
    self.____finally = func;
    return self;
  };

  //copy and wrap the methods of obj
  for(var func in obj)
  {
    if (typeof obj[func] == 'function' && obj.hasOwnProperty(func))
    {
      (function(func)
      {
        self[func] = function()
        {
          var args = [].slice.call(arguments);
          args.push(self.____next); //pass next callback to the last argument
          self.____items.push(function() //wrap the function and push into callbacks array
          {
            obj[func].apply(obj,args);
          });
          return self; //always return JSChain it self like jQuery
        }
      })(func); // this is the closure tricks
    }
  }

  //start execute the chained functions in next tick
  setTimeout(self.____next,0);
  return this;
}

module.exports = JSChain;