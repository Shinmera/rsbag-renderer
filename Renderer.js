/*
 * Global funcs
 */
var error = function(){
    var args = Array.prototype.slice.call(arguments).map(function(arg){
        if(typeof arg === 'object'){
            return JSON.stringify(arg);
        }else{
            return arg;
        }
    });
    var message = args.join(" ");
    $("main>.error").removeClass("hidden")
        .append("<span>"+message+"</span>");
    return message;
}

/*
 * Resource loader stuff
 */
var ResourceLoader = function(){
    var self = this;

    self.ErrorReporter = function(xhr, status, error, task, i){
        window.error("Error loading",task.failed.url,":",status,error);
        self.log("Error loading",task.failed.url,":",status,error);
    }

    self.callIfDone = function(task){
        var done = true;
        $.each(task.urls, function(i, url){
            if(task.data[i] === null){
                done = false;
            }
        });
        if(done){
            task.success.apply(null, task.data);
        }
    }

    self.schedule = function(task, url){
        self.log("Scheduling", url.url);
        var i = task.urls.push(url)-1;
        task.data[i] = null;
        return jQuery.ajax(url).success(function(data){
            if(!task.failed){
                task.data[i] = data;
                self.log("Completed loading",url.url);
                self.callIfDone(task);
            }
        }).fail(function(xhr, status, error){
            task.failed = url;
            task.failure(xhr, status, error, task, i);
        });
    }

    self.makeTask = function(success, failure){
        return {
            "success": success,
            "failure": failure || self.ErrorReporter,
            "urls": [],
            "data": [],
            "failed": false
        };
    }

    self.load = function(urls, success, failure){
        var task = self.makeTask(success, failure);

        $.each(urls, function(i, url){
            self.schedule(task, url);
        });
        return task;
    }

    self.loadSequentially = function(urls, success, failure){
        var task = self.makeTask(success, failure);
        $.each(urls, function(i, url){
            if(0==i)return;
            var prevTask = task;
            task = self.makeTask(function(data){
                self.schedule(prevTask, url);
            });
        });
        self.schedule(task,urls[0]);
        return task;
    }
}

ResourceLoader.prototype.log = function(message){
    var args = $.extend([], arguments);
    args.unshift("[ResourceLoader]");
    console.log.apply(console, args);
    return true;
}


/*
 * Visualizer superclass
 */
var Visualizer = function(html){
    var self = this;
    self.html = html;

    self.clear = function(){
        throw "Visualizer must implement the clear() method!";
    }
    
    self.show = function(data){
        throw "Visualizer must implement the show(data) method!";
    }
    
    return self;
}

/*
 * Main Renderer class
 */
var Renderer = function(player, resolution, frames){
    var self = this;
    var actualPlayer = player
        || null;
    var actualResolution = resolution
        || parseInt($(actualPlayer).data("resolution"))
        || (self.log("Warn: No resolution given or found, defaulting to",30) && 30);
    var actualFrames = frames
        || parseInt($(actualPlayer).data("frames"))
        || 0;

    if(actualPlayer == null) throw "No player given to renderer!";
    
    self.player = $(actualPlayer);
    self.resolution = actualResolution;
    self.speed = 1;
    self.frame = 0;
    self.accurateFrame = 0;
    self.frames = self.allocateArray(actualFrames);
    self.framesLoaded = 0;
    self.visualizers = {};

    self.updateDisplay = function(){
        var pad = function(thing, count){
            thing = ""+thing;
            count = (count || 2) - thing.length;
            return (count<0)? thing : new Array(count+1).join("0")+thing;
        }
        // Update frame info
        var seconds = self.frame / self.resolution;
        var msecs = self.frame % self.resolution / self.resolution * 1000;
        var secs = Math.floor(seconds) % 60;
        var mins = Math.floor(seconds / 60);
        var text = pad(mins)+":"+pad(secs)+":"+pad(msecs,3);
        $(".frameinfo", self.player).html(text+"<br/>"+pad(self.frame,9));
        // Show Speed
        $(".speed", self.player).text(self.speed);
        // Calculate seeker next, since the previous might change the available width
        var displayUnit = $(".seeker", self.player).width()/self.frames.length;
        $(".seeker .loaded", self.player).width(self.framesLoaded*displayUnit+"px");
        $(".seeker .current", self.player).width(self.frame*displayUnit+"px");
        // Update visualizers
        $.each(self.visualizers, function(i, visualizer){
            visualizer.show(self.frames[self.frame]);
        });
        return text;
    }

    self.frameData = function(frame){
        var actframe = frame || self.frame;
        return (actframe<self.framesLoaded && 0<=actframe) ? self.frames[actframe] : null;
    }

    self.setFrame = function(newframe){
        newframe = Math.floor(newframe);
        var data = self.frameData(newframe);
        if(data && newframe != self.frame){
            // Check if frame is within range of accurate measurement
            // if not, adjust our accurate measurement to the clamped one.
            if(newframe != Math.floor(self.accurateFrame))
                self.accurateFrame = newframe;
            self.frame = newframe;
            self.updateDisplay();
        }
        return self.frame;
    }

    self.setFrameData = function(data){
        self.frames = data;
        self.framesLoaded = data.length;
        self.setFrame(0);
        return self.frames;
    }

    self.addFrameData = function(data){
        for(var i=0; i<data.length; i++){
            self.frames[i+self.framesLoaded] = data[i];
        }
        if(self.framesLoaded == 0 && data.length>0){
            self.frame = 0;
        }
        self.framesLoaded += data.length;
        self.updateDisplay();
        return self.frames;
    }

    var playing = false;
    self.setPlaying = function(val){
        playing = val;
        if(val){
            self.log("Playing");
            $(".play,.forward,.backward", self.player).addClass("hidden");
            $(".pause,.faster,.slower", self.player).removeClass("hidden");
            if(self.frame == self.frames.length-1){
                self.setFrame(0);
            }
        }else{
            self.log("Pausing");
            $(".play,.forward,.backward", self.player).removeClass("hidden");
            $(".pause,.faster,.slower", self.player).addClass("hidden");
        }
        return playing;
    }

    self.isPlaying = function(){
        return playing;
    }

    self.setSpeed = function(speed){
        if(speed != self.speed && 0 < speed){
            self.speed = speed;
            self.updateDisplay();
        }
        return self.speed;
    }

    self.seekerFrame = function(ev){
        var seeker = $(".seeker", self.player);
        var x = ev.pageX - seeker.offset().left;
        return Math.floor(x/seeker.width()*self.frames.length);
    }

    self.loadVisualizer = function(js, html, css){        
        // Create function object from raw text
        var funct = new Function(js);
        var prototype = funct();
        var name = prototype.identifier;
        window[name] = prototype;
        
        var initiator = function(){
            var instance = new prototype(container);
            self.visualizers[name] = instance;
            if(0 < self.framesLoaded) instance.show(self.frames[self.frame]);
            self.log("Loaded visualizer",name,".");
        }
        
        // Inject CSS
        var style = $("<style type=\"text/css\" />").attr("data-visualizer", name).html(css||"");
        $("head").append(style);
        
        // Inject HTML
        var html = $($.parseHTML(html));
        var container = $('<div class="visualizer"></div>').attr("data-visualizer",name).append(html);
        $(".visualizations",self.player).append(container);

        if(prototype.dependencies){
            resourceLoader.loadSequentially(prototype.dependencies, initiator);
        }else{
            initiator();
        }

        return prototype;
    }

    self.initUI = function(){
        $(".backward", self.player).click(function(){self.setFrame(self.frame-1);});        
        $(".play", self.player).click(function(){self.setPlaying(true);});
        $(".forward", self.player).click(function(){self.setFrame(self.frame+1);});
        
        $(".slower", self.player).click(function(){self.setSpeed(self.speed/2);});
        $(".pause", self.player).click(function(){self.setPlaying(false);});
        $(".faster", self.player).click(function(){self.setSpeed(self.speed*2);});

        $(".reset-speed", self.player).dblclick(function(){self.setSpeed(1);});
        
        var wasplaying = false;
        var isholding = false;
        $(".seeker", self.player).mousedown(function(ev){
            isholding = true;
            wasplaying = self.isPlaying();
            self.setPlaying(false);
            self.setFrame(self.seekerFrame(ev));
        });
        
        $(window).mousemove(function(ev){
            if(isholding){
                self.setFrame(self.seekerFrame(ev));
            }
        }).mouseup(function(ev){
            if(isholding){
                isholding = false;   
                self.setPlaying(wasplaying);
            }
        }).resize(function(ev){
            self.updateDisplay();
        });
        return true;
    }

    var frameDuration = 0;
    var lastFrameTime = 0;
    self.step = function(){
        var now = performance.now();
        if(0 < lastFrameTime)
            frameDuration = now-lastFrameTime;
        lastFrameTime = now;

        if(self.isPlaying() && self.frame<self.framesLoaded-1){
            // Calculate next frame by approximating time distance
            // through previous time taken to render the frame.
            var frameDistance = (frameDuration/1000)*self.resolution*self.speed;
            self.accurateFrame += frameDistance;
            self.setFrame(Math.min(self.framesLoaded-1,self.accurateFrame));
            if(self.frame == self.framesLoaded-1){
                self.setPlaying(false);
            }
        }

        window.requestAnimationFrame(self.step);
        return frameDuration;
    };

    self.initUI();
    self.step();

    return self;
}

Renderer.prototype.log = function(message){
    var args = $.extend([], arguments);
    args.unshift("[Renderer]");
    console.log.apply(console, args);
    return true;
}

Renderer.prototype.allocateArray = function(length){
    var array = [];
    for(var i=0; i<length; i++){
        array[i]=null;
    }
    return array;
}
