exception Quit

val debug_mode : bool
val profile_mode : bool
val failed_Count : int ref
val success_count : int ref

type stats = {
  compact_percent : int list ref
}

val stats : stats

val print_debugging_info : unit -> unit

module Field : sig
  type t
  val compare : t -> t -> int
  val hash : t -> int 
  val as_int : t -> int
  val equal : t -> t -> bool 
  val to_string : t -> string
  val of_string : string -> t
  val choose : unit -> t
end
module FieldArray : sig
  type 'a t
  val make : 'a -> 'a t
  val init : (Field.t -> 'a) -> 'a t
  val set : 'a t -> Field.t -> 'a -> unit 
  val get : 'a t -> Field.t -> 'a
  val fold : ( Field.t -> 'a -> 'b -> 'b) -> 'a t -> 'b -> 'b
  val copy : 'a t-> 'a t
  val size : 'a t -> int
end 
module FieldSet : sig 
  include Set.S with type elt = Field.t
  val of_list : Field.t list -> t
end
  
module Value : sig
  type t 
  val compare : t -> t -> int
  val hash : t -> int 
  val as_int : t -> int
  val equal : t -> t -> bool 
  val to_string : t -> string
  val of_string : string -> t
  val extra_val : t
end
module ValueSet : sig 
  include Set.S with type elt = Value.t
  val of_list : Value.t list -> t
end

module SetMapF :
  functor (K : Map.OrderedType) ->
  functor (V : Set.OrderedType) -> sig
    type t
    type elt = V.t
    module Values : Set.S with type elt = elt
    type eltSet = Values.t
    type key = K.t
    val empty : t
    val add : key -> elt -> t -> t
    val is_empty : t -> bool
    val union : t -> t -> t
    val keys : t -> key list
    val find_all : key -> t -> eltSet

    val to_string : t -> (key -> string -> string, unit, string) format ->
      (elt list -> string list) -> string
  end

module UnivMap : sig 
  type t = SetMapF(Field)(Value).t
end

val all_fields : (unit -> FieldSet.t) ref 
val all_values : (unit -> (Field.t -> ValueSet.t)) ref
val set_univ : UnivMap.t list -> bool


module WorkList : functor (K:Set.OrderedType) -> 
sig
  type t 
  val add : K.t -> t -> t
  val singleton : K.t -> t
  val is_empty : t -> bool
  val hd : t -> K.t
  val tl : t -> t
  val all_seen_items : t -> K.t list
end

module UnionFind : functor(Ord : Map.OrderedType) -> 
sig
  type union_find_ds
  val init_union_find : unit -> 
    ((union_find_ds ref -> union_find_ds ref -> bool)* 
	(Ord.t -> union_find_ds ref) * 
	(union_find_ds ref -> union_find_ds ref -> 
	 union_find_ds ref))
end

val remove_duplicates : 'a list -> 'a list

val thunkify : (unit -> 'a) -> (unit -> 'a)

