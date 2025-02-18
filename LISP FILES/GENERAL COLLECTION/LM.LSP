; REVISION RECORD
; 04-20-91
;  Added several new features:
;      Multiple groups with names.
;      Pick entities for group.
;      Set group name by picking entity in group.
;      Save groups in data file (dwgname.LM).
;      Select all entities on specified layer or layer group
; 06-09-91
;  VER 2.1 - Added more features:
;      Isolate entities on a chosen layer (I)solate.
;      Change entity to layer by picking entity(s) and destination.
; 09-01-91
;  VER 2.2 - Added more features, enhanced existing features
;      Select for a group fixed so that previous thawed layers are restored
;      Layer color added
;      Layer renaming with wild card * for prefix and sequential number for suffix
;      Fixed grouping to disallow layers' existence in multiple groups
; 01-11-92
;  VER 3.0 - Changed grouping to allow multiple layer existence on default
;      layer only
;      Added display by dragging with grread for layers and groups
;      Enhanced group isolation by calling layer isolation so that a group
;      and then additional single layers could be isolated
;      Added Thaw ALL to LM commands
;      Added Merge to LM commands
;      Changed Move to V from M to accomodate Merge
;
;      Changes made by RPR of RAS Inc. 8/22/95
;      Changed "FreeZe" option to "Z".
;      Added "OFF" option as letter "F".
;
;      Changes made by RPR of RAS Inc. 8/22/95
;      Modified "Display" option to display entity type and layer



;(prompt "\n  Loading Layer Master.  Please wait.")

(defun lmerr (st)
   (setq *error* olderr)
   (if (= st "Function cancelled")
       (prompt "\nLMERR: Function cancelled.")
       (prompt (strcat "\nLMERR: " st))
   )
   (setq lyrset nil)
   (setq ss nil)
   (prin1)
)

(defun strpos (str1 str2 start / ndx st1 st2)
   (setq st1 (strcat str1 ","))
   (setq st2 (strcat str2 ","))
   (setq p nil)
   (setq ndx start)
   (while (and (not p) (<= ndx (strlen st2)))
       (if (= (substr st2 ndx (strlen st1)) st1)
	   (setq p ndx)
	   (setq ndx (+ ndx 1))
       )
   )
   p
)

(defun getlyrs (/ thwdlyrs)
   (setq thwdlyrs (getvar "clayer"))
   (setq lyrnext (tblnext "layer" t))
   (while lyrnext
       (if (and (not (strpos (cdr (assoc 2 lyrnext)) thwdlyrs 1)) (= (cdr (assoc 70 lyrnext)) 64))
	   (setq thwdlyrs (strcat thwdlyrs (cdr (assoc 2 lyrnext)) ","))
       )
       (setq lyrnext (tblnext "layer"))
   )
   (setq thwdlyrs (substr thwdlyrs 1 (- (strlen thwdlyrs) 1)))
   thwdlyrs
)

(defun getgrp (gn / lyrnext lyrsthwd i ent group_name old_layers lyrs j lyr lt)
   (setq group_name gn)
   (setq lyrsthwd '())
   (setq ent (entsel (strcat "\nPick entity for group " group_name " or press <enter> for all thawed layers: ")))
   (if ent
       (progn
	   (while ent
	       (setq lyrsthwd (append lyrsthwd (list (cdr (assoc 8 (entget (car ent)))))))
	       (setq ent (entsel (strcat "\nPick entity for group " group_name ": ")))
	   )
	   (prompt "\nGrouping chosen layers.  Please wait ...")
       )
       (progn
	   (prompt "\nGrouping all thawed layers.  Please wait ...")
	   (setq lyrsthwd (append lyrsthwd (list (getvar "clayer"))))
	   (tblnext "layer" t)
	   (while (setq lyrnext (tblnext "layer"))
	       (if (and (/= (cdr (assoc 2 lyrnext)) (nth 0 lyrsthwd)) (= (cdr (assoc 70 lyrnext)) 64))
		   (setq lyrsthwd (append lyrsthwd (list (cdr (assoc 2 lyrnext)))))
	       )
	    )
	)
   )
   (if lyrgrps
       (if (setq old_layers (assoc group_name lyrgrps))
	   (setq lyrs (strcat (cdr old_layers) ","))
	   (setq lyrs  "")
       )
       (setq lyrs "")
   )
   (setq lt lyrsthwd)
   (foreach j lyrgrps
       (if (/= group_name "")
	   (foreach i lyrsthwd
	       (if (strpos i (cdr j) 1)
		   (progn
		       (prompt (strcat "\nRemoving layer " i " it is already a member of layer group " (car j) "."))
		       (setq lt (subst nil i lt))
		   )
	       )	   )
       )
   )
   (setq lyrsthwd '())
   (foreach i lt
       (if (/= i nil)
	   (setq lyrsthwd (cons i lyrsthwd))
       )
   )
   (setq lt nil)
   (foreach i lyrsthwd
       (if (not (strpos i lyrs 1))
	   (setq lyrs (strcat lyrs i ","))
       )
   )
   (if (/= lyrs "")
       (setq lyrs (substr lyrs 1 (- (strlen lyrs) 1)))
   )
   (prompt " done.")
   lyrs
)


(defun setlyr (/ ent)
   (setq ent (entsel "\nSet new current layer.  Choose entity: "))
   (if ent
       (command ".LAYER" "s" (cdr (assoc 8 (entget (car ent)))) "")
   )
)

(defun frzlyr (/ lyrstr ent)
   (setq lyrstr "")
   (setq ent (entsel "\nFreeze layer.  Choose entity: "))
   (while ent
       (setq lyrstr (strcat lyrstr (cdr (assoc 8 (entget (car ent)))) ","))
       (setq ent (entsel "\nFreeze layer.  Choose entity: "))
   )
   (if (/= lyrstr "")
       (progn
	   (setq lyrstr (substr lyrstr 1 (- (strlen lyrstr) 1)))
	   (command ".LAYER" "f" lyrstr "")
       )
   )
)

(defun offlyr (/ lyrstr ent)
   (setq lyrstr "")
   (setq ent (entsel "\nTurn off layer.  Choose entity: "))
   (while ent
       (setq lyrstr (strcat lyrstr (cdr (assoc 8 (entget (car ent)))) ","))
       (setq ent (entsel "\nOFF layer.  Choose entity: "))
   )
   (if (/= lyrstr "")
       (progn
	   (setq lyrstr (substr lyrstr 1 (- (strlen lyrstr) 1)))
	   (command ".LAYER" "off" lyrstr "")
       )
   )
)

(defun chglyr (/ lyrset)
   (prompt "\nChange entity(s) to CURRENT layer.")
   (setq lyrset (ssget))
   (if lyrset
       (command ".CHPROP" (eval lyrset) "" "la" (getvar "clayer") "")
   )
   (setq lyrset nil)
   (gc)
)

(defun movelyr (/ lyrset dest_lyr)
   (prompt "\nMove entity(s) to selected layer.")
   (setq lyrset (ssget))
   (if lyrset
       (progn
	   (setq dest_lyr (entsel "\nPick an entity on the destination layer: "))
	   (if dest_lyr
	       (progn
		   (setq dest_lyr (cdr (assoc 8 (entget (car dest_lyr)))))
		   (command ".CHPROP" (eval lyrset) "" "la" dest_lyr "")
	       )
	   )
       )
   )
   (setq lyrset nil)
   (gc)
)

(defun mergelyrs (/ lyrset dest_lyr source_lyr ent1 ent2)
   (prompt "\nMerge two layers:")
   (setq ent1 (entsel "\nPick an entity on the layer that is to remain: "))
   (if ent1
       (progn
	   (setq dest_lyr (cdr (assoc 8 (entget (car ent1)))))
	   (setq ent2 (entsel "\nPick an entity on the layer to be emptied: "))
	   (if ent2
	       (progn
		   (setq source_lyr (cdr (assoc 8 (entget (car ent2)))))
		   (setq lyrset (ssget "X" (list (cons 8 source_lyr))))
		   (command ".CHPROP" (eval lyrset) "" "la" dest_lyr "")
	       )
	   )
       )
   )
   (setq lyrset nil)
   (gc)
)

(defun isolate (lyrs / lyrstr ent lyrsisol)
   (setq lyrsisol lyrs)
   (if lyrsisol
       (setq lyrstr (strcat (cdr lyrgroup) ","))
       (setq lyrstr "")
   )
   (setq ent (entsel "\nIsolate layer(s).  Choose entity: "))
   (while ent
       (setq lyrstr (strcat lyrstr (cdr (assoc 8 (entget (car ent)))) ","))
       (setq ent (entsel "\nIsolate layer(s).  Choose entity: "))
   )
   (if (/= lyrstr "")
       (progn
	   (setq lyrstr (substr lyrstr 1 (- (strlen lyrstr) 1)))	   (command ".LAYER" "s" (substr lyrstr 1 (- (strpos "" lyrstr 1) 1)) "f" "*" "t" lyrstr "")
       )
   )
)

(defun renlyr (/ lyrstr ent lyrlist pos newname ndx i j)
   (setq lyrlist '())
   (setq ent (entsel "\nRename layer(s).  Choose entity: "))
   (while ent
       (setq lyrlist (cons (cdr (assoc 8 (entget (car ent)))) lyrlist))
       (setq ent (entsel "\nRename layer(s).  Choose entity: "))
   )
   (if lyrlist
       (progn
	   (setq lyrlist (reverse lyrlist))
	   (foreach j lyrlist
	       (setq newname (strcase (getstring (strcat "\nCurrent name is: " j ".  What is the new name? "))))
	       (if (not (tblsearch "LAYER" newname))
		   (progn
		       (if lyrgrps
			   (foreach i lyrgrps
			       (if (setq pos (strpos j (cdr i) 1))
				   (progn
				       (setq lyrlist (strcat (substr (cdr i) 1 (- pos 1)) newname (substr (cdr i) (+ pos (strlen newname)))))
				       (setq lyrgrps (subst (cons (car i) lyrlist) (assoc (car i) lyrgrps) lyrgrps))
				   )
			       )
			   )
		       )
		       (command ".RENAME" "la" j newname)
		   )
		   (prompt (strcat "\nLayer " j " exists.  Rename unsuccessful."))
	       )
	   )
       )
   )
)

(defun lyrcolor (/ lyrstr ent clr)
   (setq lyrstr "")
   (setq ent (entsel "\nChange layer color.  Choose entity: "))
   (while ent
       (setq lyrstr (strcat lyrstr (cdr (assoc 8 (entget (car ent)))) ","))
       (setq ent (entsel "\nChange layer color.  Choose entity: "))
   )
   (if (/= lyrstr "")
       (progn
	   (setq clr (strcase (getstring (strcat "\nWhat color for layer(s) " lyrstr "? "))))
	   (if (or (member (substr clr 1 1) clrs) (and (> (atoi clr) 0) (< (atoi clr) 256)))
	       (progn
		   (setq lyrstr (substr lyrstr 1 (- (strlen lyrstr) 1)))
		   (command ".LAYER" "c" clr lyrstr "")
	       )
	       (prompt (strcat "\n" clr " is not a valid color number or a standard color name."))
	   )
       )
   )
)

(defun get_group (ask_pick ask_group / ent n group_name ap ag lg)
   (if lyrgrps
       (progn
	   (setq ap ask_pick)
	   (setq ag ask_group)
	   (if ap
	       (progn
		   (setq ent (entsel "\nPick entity in group or press <enter> to input group name: "))
		   (if ent
		       (progn
			   (setq ent (entget (car ent)))
			   (setq ndx 0)
			   (while (setq n (nth ndx lyrgrps))
			       (if (strpos (cdr (assoc 8 ent)) (cdr n) 1)
				   (setq group_name (car n))
			       )
			       (setq ndx (+ ndx 1))
			   )
		       )
		       (setq group_name nil)
		   )
	       )
	   )
	   (if (and ag (not group_name))
	       (progn
		   (setq group_name (getstring "\nGroup name: "))
		   (setq group_name (strcase group_name))
	       )
	   )
       )
       (prompt "\nNo defined layer groups exist!")
   )
   (if (not group_name)
       nil
       (progn
	   (if ent
	       (prompt group_name)
	   )
	   (assoc group_name lyrgrps)
       )
   )
)

(defun readlgs (/ f group_name lyrs lgs)
   (setq lgs '())
   (setq f (open (strcat (getvar "dwgname") ".lm") "r"))
   (if f
       (progn
	   (setq group_name (read-line f))
	   (while group_name
	       (setq lyrs (read-line f))
	       (setq lgs (cons (cons group_name lyrs) lgs))
	       (setq group_name (read-line f))
	   )
	   (close f)
       )
   )
   lgs
)

(defun writlgs (/ f n)
   (setq f (open (strcat (getvar "dwgname") ".lm") "w"))
   (foreach n lyrgrps
       (write-line (car n) f)
       (write-line (cdr n) f)
   )
   (close f)
)

(defun lm_help ()
   (textscr)
   (prompt "\nLayer Master Main Command Set:")
   (prompt "\n  freeZe - Freeze layer by picking any entity on that layer.")
   (prompt "\n     oFf - Turn off layer by picking any entity on that layer.")
   (prompt "\n     Set - Set the current layer by picking any entity on that layer.")
   (prompt "\n    Thaw - Thaw ALL layers.")
   (prompt "\n  Change - Pick any entity to change it's layer to the current layer.")
   (prompt "\n Isolate - Pick entity(s) to Isolate layer(s).  Entity layers not picked")
   (prompt "\n           will be frozen.")
   (prompt "\n  seLect - Pick any entity and all entities on that layer will be")
   (prompt "\n           placed in the PREVIOUS selection set.")
   (prompt "\n    moVe - Move selected entities to another layer by picking them and then")
   (prompt "\n           picking an entity on the destination layer.")
   (prompt "\n   cOlor - Change layer color.  Pick an entity and name the desired color.")
   (prompt "\n  Rename - Pick entities and rename their layer(s).")
   (prompt "\n Display - Move the cursor near an entity and view it's layer and group")
   (prompt "\n           on the status line.")
   (prompt "\n   Merge - Merge two layers.  All entities from second pick will be moved")
   (prompt "\n           to layer from first pick.")
   (prompt "\n   Group - Layer group commands.")
   (prompt "\n    Help - Displays this screen.")
   (prompt "\n  <Q>uit - Default command.  Quit Layer Master.")
   (prompt "\nPress your favorite key ...")
   (getstring)
   (graphscr)
)

(defun group_help ()
   (textscr)
   (prompt "\nLayer Master Layer Group Command Set:")
   (prompt "\n  Freeze - Freeze a layer group by picking any entity in that group or")
   (prompt "\n           by typing it's name.")
   (prompt "\n    Thaw - Thaw any layer group by picking an entity in the group or by")
   (prompt "\n           typing it's name.")
   (prompt "\n Isolate - Isolate a layer group and singley chosen layers by picking")
   (prompt "\n           any entity in that group and then any additional layers not")
   (prompt "\n           in the group.")
   (prompt "\n  Define - Define a layer group by picking entities on different layers")
   (prompt "\n           or press <enter> to group all currently thawed layers.")
   (prompt "\n           The default group has no name.  It is the only group that")
   (prompt "\n           can contain a layer already existing in another group.")
   (prompt "\n           Access it with the enter key.")
   (prompt "\nUndefine - Remove a layer group's definition from the group configuration.")
   (prompt "\n   Print - List all layer groups or pick any entity to check it's group name.")
   (prompt "\n    Save - Save group configuration to disk in file DWGNAME.LM.")
   (prompt "\n  seLect - Pick any entity and all entities in that layer group will be")
   (prompt "\n           placed in the PREVIOUS selection set.")
   (prompt "\n   cOlor - Change the color of ALL layers in a group by picking any entity")
   (prompt "\n           in that group and naming the desired color.")
   (prompt "\n  Rename - Pick any entity in a group and rename the group.")
   (prompt "\n    Help - Display this screen.")
   (prompt "\n  <Q>uit - Default command.  Quit group commands.")
   (prompt "\nPress your favorite key ...")
   (getstring)
   (graphscr)
)

(defun viewwndw (/ vc vs scrsz scl vsx llcx llcy)
   (setq vc (getvar "viewctr"))
   (setq vs (getvar "viewsize"))
   (setq scrsz (getvar "screensize"))
   (setq scl (/ (nth 0 scrsz) (nth 1 scrsz)))
   (setq vsx (* vs scl))
   (setq llcx (- (nth 0 vc) (/ vsx 2.0)))
   (setq llcy (- (nth 1 vc) (/ vs 2.0)))
   (list (list llcx llcy) (list (+ llcx vsx) (+ llcy vs)))
)

(defun grr (/ q pk lastpt pt sel e ent str)
   (setq q nil pk nil)
   (setq lastpt nil)
   (setq e (entget (entlast)))
   (princ "\n")
   (while (not q)
     (if (not pk)
       (setq pt (grread 5))
       (setq pt (entsel (strcat "\r")))
     )
     (if (not pt)
       (setq q t)
       (if (or (= (car pt) 6) (= (car pt) 2))
         (if (and (= (car pt) 2)(or (= (cadr pt) 80)(= (cadr pt) 112)))
           (progn
             (setq pk t)
             (prompt "\nPress <enter> when finished...")
             (prompt "\nPick entities.")
             (prompt "\n ")
           )
           (setq q t)
         )
         (if (not (equal pt lastpt))
           (progn
             (setq sel (nentselp (cadr pt)))
             (if sel
               (progn
                 (redraw (cdr (assoc -1 e)) -4)
                 (setq ent (car sel))
                 (setq e (entget ent))
                 (redraw (cdr (assoc -1 e)) -3)
                 (setq str (strcat "\r  Entity type: " (cdr (assoc 0 e))))
                 (if (= (type (car (last sel))) 'ENAME)
                   (setq str (strcat str " in block: "
                     (cdr (assoc 2 (entget (last (last sel)))))))
                 )
                 (setq n (- 45 (strlen str)))
                 (while (< 0 n)
                   (setq str (strcat str " "))
                   (setq n (1- n))
                 )
                 (setq str (strcat str "Entity layer: " (cdr (assoc 8 e))))
                 (setq n (- 90 (strlen str)))
                 (while (< 0 n)
                   (setq str (strcat str " "))
                   (setq n (1- n))
                 )
		 (if (equal (cdr (assoc 0 e)) "LWPOLYLINE")
                   (setq str (strcat str "Entity elevation: " (rtos (cdr (assoc 38 e)))))
                   (setq str (strcat str "Entity elevation: " (rtos (caddr (cdr (assoc 10 e))))))
                 )
                 (setq n (- 120 (strlen str)))
                 (while (< 0 n)
                   (setq str (strcat str " "))
                   (setq n (1- n))
                 )
                 (princ str)
               )
             )
             (setq lastpt pt)
           )
         )
       )
     )
   )
   (grtext)
   (redraw (cdr (assoc -1 e)) -4)
   (setq ent nil)
)


(defun c:lm (/ fs ansr ce ftd ansr gn ent vw i lg currlyrs clr clrs newname lyrgroup)

  (setq olderr *error*)
  (setq *error* lmerr)
  (setq clrs '("R" "Y" "G" "C" "B" "M" "W"))

   (if (not lyrgrps)
       (progn
	   (setq lyrgrps (readlgs))
	   (if (not lyrgrps)
	       (setq lyrgrps '())
	   )
       )
   )
   (setq ce (getvar "cmdecho"))
   (setvar "cmdecho" 0)
   (initget "F f Z z S s C c L l G g Q q H h")
   (setq fs (getstring "\nLM Command (F/Z/S/T/C/I/L/V/O/R/D/M/G/Help/<Q>): "))
   (setq fs (strcase fs))
   (if (= fs "")
       (setq fs "Q")
   )
   (while (/= fs "Q")
       (cond
	   ((= fs "F")
	       (offlyr)
	   )
	   ((= fs "Z")
	       (frzlyr)
	   )
	   ((= fs "S")
	       (setlyr)
	   )
	   ((= fs "C")
	       (chglyr)
	   )
	   ((= fs "G")
	       (setq ftd (getstring "\nLM Group command (F/T/I/D/U/P/S/L/O/R/Help/<Q>): "))
	       (setq ftd (strcase ftd))
	       (if (= ftd "")
		   (setq ftd "Q")
	       )
	       (while (/= ftd "Q")
		   (cond
		       ((= ftd "F")
			   (setq lyrgroup (get_group t t))
			   (if lyrgroup
			       (command ".LAYER" "f" (cdr lyrgroup) "")
			   )
		       )
		       ((= ftd "T")
			   (setq lyrgroup (get_group t t))
			   (if lyrgroup
			       (command ".LAYER" "t" (cdr lyrgroup) "")
			   )
		       )
		       ((= ftd "I")
			   (setq lyrgroup (get_group t t))
			   (if lyrgroup
			       (isolate lyrgroup)
;				(command ".LAYER" "t" (substr (cdr lyrgroup) 1 (- (strpos "" (cdr lyrgroup) 1) 1)) "s" (substr (cdr lyrgroup) 1 (- (strpos "" (cdr lyrgroup) 1) 1)) "f" "*" "t" (cdr lyrgroup) "")
			   )
		       )
		       ((= ftd "D")
			   (setq gn (getstring "\nGroup name or <enter> for default group: "))
			   (setq gn (strcase gn))
			   (setq lyrgroup (assoc gn lyrgrps))
			   (setq ansr nil)
			   (if lyrgroup
			       (progn
				   (setq ansr "")
				   (setq ansr (getstring (strcat "\nGroup " gn " already exists.  Redefine it? (Y/<N>): ")))
				   (setq ansr (strcase ansr))
			       )
			   )
			   (if (or (not ansr) (= ansr "Y"))
			       (progn
				   (setq lg '())
				   (foreach i lyrgrps
				       (if (not (equal i gn))
					   (setq lg (cons i lg))
				       )
				   )				       (setq lyrgrps lg)
				   (setq lg nil)
				   (setq lyrgroup (getgrp gn))
				   (if (/= lyrgroup "")
				       (if (assoc gn lyrgrps)
					   (setq lyrgrps (subst (cons gn lyrgroup) (assoc gn lyrgrps) lyrgrps))
					   (setq lyrgrps (cons (cons gn lyrgroup) lyrgrps))
				       )
				       (prompt (strcat "\nLayer group " gn " not defined."))
				   )
			       )
			   )
		       )
		       ((= ftd "U")
			   (setq gn (get_group t t))
			   (if gn
			       (progn
				   (setq lg '())
				   (foreach i lyrgrps
				       (if (not (equal i gn))
					   (setq lg (cons i lg))
				       )
				   )
				   (setq lyrgrps lg)
				   (setq lg nil)
			       )
			   )
		       )
		       ((= ftd "P")
			   (setq gn (get_group t nil))
			   (if (not gn)
			       (progn
				   (prompt "\nDefined layer groups: \n")
				   (foreach n lyrgrps
				       (write-line (strcat (strcase (car n)) ":\n" (cdr n) "\n"))
				   )
				   (getstring "\nPress your favorite key ...")
			       )
			       (prompt (strcat "\nEntity picked in Group: " (car gn)))
			   )
		       )
		       ((= ftd "S")
			   (writlgs)
		       )
		       ((= ftd "L")
			   (setq lyrgroup (get_group t t))
			   (if lyrgroup
			       (progn
				   (setq currlyrs (getlyrs))
				   (prompt (strcat "\nSelecting entities in layer group: " (car lyrgroup) ".  Please wait ..."))
				   (command ".LAYER" "t" (substr (cdr lyrgroup) 1 (- (strpos "" (cdr lyrgroup) 1) 1)) "s" (substr (cdr lyrgroup) 1 (- (strpos "" (cdr lyrgroup) 1) 1)) "f" "*" "t" (cdr lyrgroup) "")
				   (command ".ZOOM" "e")
				   (setq vw (viewwndw))
				   (setq ss (ssget "c" (nth 0 vw) (nth 1 vw)))
				   (command ".ZOOM" "p")
				   (command ".LAYER" "t" currlyrs "")
				   (prompt "done.\n")
			       )
			   )
		       )
		       ((= ftd "O")
			   (setq lyrgroup (get_group t t))
			   (if lyrgroup 			      (progn
				   (setq clr (strcase (getstring (strcat "\nWhat color for group " (car lyrgroup) "? "))))
				   (if (or (member (substr clr 1 1) clrs) (and (> (atoi clr) 0) (< (atoi clr) 256)))
				       (command ".LAYER" "c" clr (cdr lyrgroup) "")
				       (prompt (strcat "\n" clr " is not a valid color number or a standard color name."))
				   )
			       )
			   )
		       )
		       ((= ftd "R")
			   (setq lyrgroup (get_group t t))
			   (if lyrgroup
			       (progn					(setq newname (strcase (getstring (strcat "\nCurrent group name is: " (car lyrgroup) ".  What is the new name? "))))
				   (if (not (assoc newname lyrgrps))
				       (setq lyrgrps (subst (cons newname (cdr lyrgroup)) (assoc (car lyrgroup) lyrgrps) lyrgrps))
				       (prompt (strcat "\nGroup " newname " exists.  Rename unsuccessful."))
				   )
			       )
			   )
		       )
		       ((= ftd "H")
			   (group_help)
		       )
		       (nil t)
		   )
		   (setq ftd (getstring "\nLM Group command (F/T/I/D/U/P/S/L/O/R/Help/<Q>): "))
		   (setq ftd (strcase ftd))
		   (if (= ftd "")
		       (setq ftd "Q")
		   )
	       )
	   )
	   ((= fs "L")
	       (setq ent (entsel "\nPick any entity for PREVIOUS selection set: "))
	       (if ent
		   (progn
		       (setq ent (entget (car ent)))
		       (prompt (strcat "\nSelecting entities on layer: " (cdr (assoc 8 ent)) ".  Please wait ..."))
		       (setq ss (ssget "x" (list (cons 8 (cdr (assoc 8 ent))))))
		       (prompt "done.\n")
		   )
	       )
	   )
	   ((= fs "I")
	       (isolate nil)
	   )
	   ((= fs "V")
	       (movelyr)
	   )
	   ((= fs "O")
	       (lyrcolor)
	   )
	   ((= fs "R")
	       (renlyr)
	   )
	   ((= fs "D")
               (prompt "\nMove cursor near entity or press 'P' to pick entity.")
               (prompt "\nPress <enter> when finished...")
	       (grr)
	   )
	   ((= fs "T")
	       (command ".layer" "t" "*" "")
	   )
	   ((= fs "M")
	       (mergelyrs)
	   )
	   ((= fs "H")
	       (lm_help)
	   )
	   (nil t)
       )
       (initget "F f S s C c G g Q q H h D d")
       (setq fs (getstring "\nLM Command (F/S/T/C/I/L/V/O/R/D/M/G/Help/<Q>): "))
       (setq fs (strcase fs))
       (if (= fs "")
	   (setq fs "Q")
       )
   )
   (setvar "cmdecho" ce)
   (setq *error* olderr)
   (prin1)
)

;(prompt "  Loading Layer Master.  Please wait.  Done.")
;(prompt "\n*** C:lm, LAYER MASTER Ver 3.0 (c) Copyright 1991, 1992 CADD Masters ***")
;(prompt "\n***        5682 Oakmont Circle  Livermore, CA  94550  415-443-6980         ***")
(prin1)
