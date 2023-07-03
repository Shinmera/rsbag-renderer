(in-package #:rsbag-renderer)

(defmacro setdocs (&body pairs)
  `(progn
     ,@(loop for (var doc) in pairs
             collect (destructuring-bind (var &optional (type 'function))
                         (if (listp var) var (list var))
                       `(setf (documentation ',var ',type) ,doc)))))

;; api.lisp
(setdocs
  (safely-parse-date
   "Attempt to parse STRING into a LOCAL-TIME:TIMESTAMP properly."))

;; config.lisp
(setdocs
  (start
   "Start the server on port 8080, open all file-sources in the \"tide/\" folder, and load all visualizers in the \"visualizers/\" folder.")
  
  (stop
   "Stop the current server, close all sources, and if QUIT is T, quit.")
  
  (main
   "Entry point for a standalone binary version."))

;; front.lisp
(setdocs
  (process
   "Process TEMPlate by invoking CLIP:PROCESS in the proper environment, supplying it with ARGS."))

;; json.lisp
(setdocs
  ((*json-output* variable)
   "Bound to the stream that the JSON functions should output to by default.")
  
  ((*started* variable)
   "Helper symbol that is T if an element was already inserted into the current JSON structure.")
  
  ((*string-replaces* variable)
   "A hash table mapping characters to strings, necessary to achieve a compliant JSON string.")
  
  (json-delimiter
   "Outputs a JSON delimiter (#\,) if necessary.

See *STARTED*")
  
  (json-null
   "Outputs a JSON null value.")
  
  (json-false
   "Outputs a JSON false value.")
  
  (json-true
   "Outputs a JSON true value.")
  
  (write-json
   "Outputs OBJECT to JSON in its appropriate format.

INTEGER => INTEGER
RATIO   => FLOAT
FLOAT   => FLOAT
STRING  => STRING
LIST    => ARRAY
VECTOR  => ARRAY
T       => PRINC-TO-STRING => STRING")
  
  (with-delimiters
    "Ensures that output in BODY is surrounded by LEFT and RIGHT on DESTINATION.
LEFT and RIGHT should be CHARACTERs.")
  
  (with-json-array
    "Outputs a JSON array. Use WITH-JSON-ENTRY or ENTRY within BODY to output array entries.")
  
  (with-json-entry
    "Ensures that the output in BODY is correctly interpreted as an ENTRY.

See JSON-DELIMITER")
  
  (with-json-object
    "Outputs a JSON object. Use WITH-JSON-VALUE or PAIR within BODY to output object entries.")
  
  (with-json-value
    "Ensures that KEY is a KEY and the output in BODY is correctly interpreted as a value.

See JSON-DELIMITER")
  
  (with-json-output
    "Binds *JSON-OUTPUT* to a suitable STREAM.
If STREAM is a constant NIL, *JSON-OUTPUT* is an output-string-stream."))

;; server.lisp
(setdocs
  ((*page* variable)
   "An EQL hash-table associating page names to lists with a dispatch URI and a function.")
  
  (page
   "Return the list of (URI FUNCTION) associated with the page ID.")
  
  (remove-page
   "Remove the page named by ID.")
  
  (list-pages
   "List all known page lists.")
  
  (define-page
   "Define a new page with name NAME on URI (a regex) where URI-REGISTERS are bound to the corresponding register-groups within the URI. BODY is evaluated if the page is called.

See CL-PPCRE:REGISTER-GROUPS-BIND")
  
  (dispatch
   "Dispatch to the page that matches the path TO.")
  
  ((*api* variable)
   "An EQL hash-table associating API endpoint names to functions.")
  
  (api
   "Return the API endpoint function for the API name ID.")
  
  (remove-api
   "Remove the API endpoint named by ID.")
  
  (list-apis
   "List all known API endpoint functions.")
  
  (args-missing
   "Condition signalled when required argument/s are missing from an API call.")
  
  (args
   "A list of argument names that are required but missing from the API call.")
  
  (endpoint-missing
   "Condition signalled when an API call went to a missing endpoint.")
  
  (endpoint
   "The endpoint that was requested but is missing.")
  
  (bindings-from-args
   "Generate a list of LET bindings that will establish the necessary variables for the function.
This grabs the values from POST/GET. The lambda-list represented by ARGS only allows &optional.")
  
  (binding-check
   "Generate a LOOP form that will check all required arguments in ARGS for values.
All missing (NIL) arguments are gathered and combined into a single ARGS-MISSING condition.")
  
  (define-api
    "Define a new API endpoint named NAME, with an api-arguments-list ARGS. BODY is evaluated when the endpoint is called.
An api-arguments-list can only have required or optional arguments.
Anything else would not make sense in the context of REST parameters.")
  
  (with-api-output
    "Constructs a standard API response with the correct STATUS, MESSAGE, and DATA fields.
The BODY is responsible for outputting the contents of the DATA field.
The *JSON-STREAM* is bound directly to the server output stream.

See SERVER-STREAM")
  
  (redirect
   "Send a redirect header to TO.")
  
  (post/get
   "Get the POST or GET parameter/s named by PARAM (case-insensitively).

If multiple possible values are found, they are returned as a list.
If only one is found, it is returned directly.")

  ((*listener* variable)
   "An EQL hash-table of port numbers to listeners.")
  
  (listener
   "Returns the listener for the given port ID.")
  
  (remove-listener
   "Removes the listener named by the port ID.")
  
  (list-listeners
   "Lists all listeners.")
  
  (start-listener
   "Start a listener on PORT.")
  
  (stop-listener
   "Stop the listener on PORT.")
  
  (post-handler
   "Handles outputting the RESULT properly by potentially transforming it into a value that Hunchentoot can handle directly.")
  
  ((*server-stream* variable)
   "If the server stream has been acquired, this variable contains it.

See SERVER-STREAM")
  
  (server-stream
   "Returns the server's output stream by sending off the currently set headers and grabbing it.

The TYPE argument only matters the first time this function is called.
If TYPE is :FLEXI, a FLEXI-STREAM is returned.
If TYPE is :OCTET, an OCTET-STREAM is returned.")
  
  (pre-handler
   "Directly handles an incoming REQUEST by Hunchentoot. Handles dispatching and error protection."))

;; source.lisp
(setdocs
  ((*source* variable)
   "An EQUAL hash-table mapping source IDs to SOURCEs.")
  
  (source
   "Returns the SOURCE associated with the given ID.")
  
  (remove-source
   "Removes the SOURCE named by the ID.

You should not use this function directly. Use CLOSE-SOURCE instead.")
  
  (list-sources
   "Lists all known SOURCEs.")
  
  ((source type)
   "Abstract superclass for all a bag source.")
  
  ((channel type)
   "Abstract superclass for all a bag channel.")
  
  (source-type
   "Returns a TYPE identifier for the given SOURCE.")
  
  (open-source
   "Opens a new source of type TYPE, using the IDENTIFIER.
The resulting identifier used to actually name the source may be
different from the identifier object given. Call IDENTIFIER on
the returned SOURCE to get the right identifier.

An opened source is automatically retrievable through SOURCE.")
  
  (close-source
   "Close the SOURCE.

A closed source is automatically unregistered, and thus no longer retrievable through SOURCE.")
  
  (channel
   "Returns a CHANNEL from the SOURCE, named by IDENTIFIER.")
  
  (channels
   "Returns a list of all CHANNELs on SOURCE.")
  
  (channel-length
   "Returns the number of events stored in the CHANNEL.")
  
  (channel-source
   "Returns the SOURCE of the CHANNEL.")
  
  (start-timestamp
   "Returns a LOCAL-TIME:TIMESTAMP of the start of the CHANNEL.")
  
  (end-timestamp
   "Returns a LOCAL-TIME:TIMESTAMP of the end of the CHANNEL.")
  
  (duration
   "Returns the duration of the CHANNEL in seconds.")
  
  (resolution
   "Returns the resolution of the CHANNEL in events per second.")
  
  (event
   "Returns the event on CHANNEL ad INDEX.
The type of the returned event is not specified.
However, you should be able to call ID, TIMESTAMP, and PAYLOAD on it.")
  
  (id
   "Returns the index of the EVENT in its CHANNEL.")
  
  (timestamp
   "Returns the LOCAL-TIME:TIMESTAMP at which the EVENT occurs.")
  
  (payload
   "Returns the payload object encapsulated by the EVENT."))

;; toolkit.lisp
(setdocs
  ((*debugger* variable)
   "If true, the debugger will be invoked if a condition is handled by DISSECT-ERROR.")
  
  ((*root* variable)
   "Contains NIL or a pathname to the root of the server.
If it is NIL, the pathname can be automatically guessed by using ROOT-PATHNAME.")
  
  (description
   "Returns a string description of OBJECT.")
  
  (identifier
   "Returns an identifier for the OBJECT through which it can be retrieved by an accessor.")

  (schema
   "Returns an abstract description of the object schema that this object accepts or returns.")
  
  ((define-storage)
   "Define a storage of BASENAME, using TEST as the element discerning test.

This creates:
A special variable of *BASENAME* containing a hash-table with TEST.
An accessor function of BASENAME taking an ID and returning the associated object.
A remover function of REMOVE-BASENAME removing the ID associated object.
A listing function of LIST-BASENAMES listing all stored objects.")
  
  (root-pathname
   "Merges PATHNAME with the root of the server.
The server root is either *ROOT*, or determined as follows:
If a directory called \"visualizers\" is found under *DEFAULT-PATHNAME-DEFAULTS*,
that is chosen as the root. Otherwise, if the directory returned by
ASDF:SYSTEM-SOURCE-DIRECTORY for :RSBAG-RENDERER exists, is used.
Finally, an error is signalled with a SET-ROOT restart that allows
to set the root interactively.")
  
  (resource
   "Calls ROOT-PATHNAME on PATH. If ERROR-P is true and the file does not exist, an error is signalled.")
  
  (template
   "Returns the template file named by PATH.

See RESOURCE")
  
  (static-file
   "Returns the static file named by PATH.

See RESOURCE")
  
  (assoc-all
   "Returns all ALIST values that match ITEM by STRING-EQUAL.
Note that, unlike CL:ASSOC, this returns the /values/, not the conses.")
  
  (ensure-list
   "Ensure that LIST is a LIST by potentially wrapping it in one if it isn't.")
  
  (maybe-unlist
   "Ensure that LIST is not a LIST by potentially unwrapping it with CAR if it is one.")
  
  (<<
   "Curry FUN by CURRY from the right.")
  
  (>>
   "Curry FUN by CURRY from the left.")
  
  (dissect-error
   "Handle ERR by emitting a logging message with the DISSECT:PRESENT output.
If *DEBUGGER* is true, it also invokes the debugger with ERR.")
  
  ((define-reducer-method)
   "Defines a combining METHOD that reduces the same function.

ACCESSOR is used to retrieve a list of sub-values of CLASS instance.
METHOD is then called on each of the list items, and reducing them by
REDUCTION. REDUCTION must be a LOOP keyword like MAXIMIZE, MINIMIZE, etc.")

  (write-string-file
   "Write STRING to PATH, superseding the file if it exists.")
  
  (read-string-file
   "Read PATH to a string."))

;; transform.lisp
(setdocs
  ((*transform* variable)
   "An EQUALP hash-table associating identifiers to TRANSFORM instances.")
  
  (transform
   "Returns the TRANSFORM associated with the given ID.")
  
  (remove-transform
   "Removes the transform named by ID.")
  
  (list-transforms
   "Lists all known TRANSFORMs.")
  
  ((transform type)
   "Container object for an event transformer function.")
  
  (transformer
   "Returns the essential transforming function of TRANSFORM.
The function may expect an arbitrary number of events, depending on how
many channels it is written for. The function should be called in a
context where *JSON-OUTPUT* is bound.

Once a transformer is instantiated, it is registered with *TRANSFORM*,
making it retrievable.")
  
  (origin
   "A pathname to the file that defines the transform.")
  
  ((define-transform)
   "Define a new transform with IDENTIFIER, and CHANNEL-EVENTS as lambda-list to the function.
The function defined should output the transformed events by using the various JSON functions.")
  
  (transform-events
   "Transform EVENTS by using the TRANSFORM.
This yields no specified return value. Instead the events are directly outputted to *JSON-OUTPUT*."))

;; visualizer.lisp
(setdocs
  ((*visualizer* variable)
   "An EQUALP hash-table associating identifiers to VISUALIZER instances.")
  
  (visualizer
   "Returns the VISUALIZER associated with the given ID.")
  
  (remove-visualizer
   "Removes the visualizer named by ID.")
  
  (list-visualizers
   "Lists all known VISUALIZERs.")
  
  ((visualizer type)
   "Container for a visualizer. Stores the JS, HTML, and CSS components amongst other data.")
  
  (path
   "Returns the base pathname used to store the visualizer files.")
  
  (js
   "Returns the string containing the JS source for the visualizer.")
  
  (html
   "Returns the string containing the HTML source for the visualizer.")
  
  (css
   "Returns the string containing the CSS source for the visualizer.")
  
  (check-visualizer-consistency
   "Ensures that the visualizer has all components it needs.
Namely: If JS is missing, an error is signalled.
If HTML or JS are missing, they're filled by an empty string.

VIS is returned.")
  
  (visualizer-file
   "Returns the specific visualizer file for pathname-TYPE and NAME.")
  
  (save-visualizer
   "Saves all available visualizer source data to their respective files.")
  
  (load-visualizer
   "Loads a visualizer from a PATH, or reloads the existing source files from disc into the VISUALIZER."))
