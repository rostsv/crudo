// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlanTemplate {

 String get id; String get name; List<int> get days; bool get active; List<PlanSlot> get slots;
/// Create a copy of PlanTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanTemplateCopyWith<PlanTemplate> get copyWith => _$PlanTemplateCopyWithImpl<PlanTemplate>(this as PlanTemplate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.days, days)&&(identical(other.active, active) || other.active == active)&&const DeepCollectionEquality().equals(other.slots, slots));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(days),active,const DeepCollectionEquality().hash(slots));

@override
String toString() {
  return 'PlanTemplate(id: $id, name: $name, days: $days, active: $active, slots: $slots)';
}


}

/// @nodoc
abstract mixin class $PlanTemplateCopyWith<$Res>  {
  factory $PlanTemplateCopyWith(PlanTemplate value, $Res Function(PlanTemplate) _then) = _$PlanTemplateCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<int> days, bool active, List<PlanSlot> slots
});




}
/// @nodoc
class _$PlanTemplateCopyWithImpl<$Res>
    implements $PlanTemplateCopyWith<$Res> {
  _$PlanTemplateCopyWithImpl(this._self, this._then);

  final PlanTemplate _self;
  final $Res Function(PlanTemplate) _then;

/// Create a copy of PlanTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? days = null,Object? active = null,Object? slots = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<int>,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,slots: null == slots ? _self.slots : slots // ignore: cast_nullable_to_non_nullable
as List<PlanSlot>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanTemplate].
extension PlanTemplatePatterns on PlanTemplate {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanTemplate() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanTemplate value)  $default,){
final _that = this;
switch (_that) {
case _PlanTemplate():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _PlanTemplate() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<int> days,  bool active,  List<PlanSlot> slots)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanTemplate() when $default != null:
return $default(_that.id,_that.name,_that.days,_that.active,_that.slots);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<int> days,  bool active,  List<PlanSlot> slots)  $default,) {final _that = this;
switch (_that) {
case _PlanTemplate():
return $default(_that.id,_that.name,_that.days,_that.active,_that.slots);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<int> days,  bool active,  List<PlanSlot> slots)?  $default,) {final _that = this;
switch (_that) {
case _PlanTemplate() when $default != null:
return $default(_that.id,_that.name,_that.days,_that.active,_that.slots);case _:
  return null;

}
}

}

/// @nodoc


class _PlanTemplate extends PlanTemplate {
  const _PlanTemplate({required this.id, required this.name, final  List<int> days = const <int>[], this.active = true, final  List<PlanSlot> slots = const <PlanSlot>[]}): _days = days,_slots = slots,super._();
  

@override final  String id;
@override final  String name;
 final  List<int> _days;
@override@JsonKey() List<int> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}

@override@JsonKey() final  bool active;
 final  List<PlanSlot> _slots;
@override@JsonKey() List<PlanSlot> get slots {
  if (_slots is EqualUnmodifiableListView) return _slots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_slots);
}


/// Create a copy of PlanTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanTemplateCopyWith<_PlanTemplate> get copyWith => __$PlanTemplateCopyWithImpl<_PlanTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanTemplate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._days, _days)&&(identical(other.active, active) || other.active == active)&&const DeepCollectionEquality().equals(other._slots, _slots));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_days),active,const DeepCollectionEquality().hash(_slots));

@override
String toString() {
  return 'PlanTemplate(id: $id, name: $name, days: $days, active: $active, slots: $slots)';
}


}

/// @nodoc
abstract mixin class _$PlanTemplateCopyWith<$Res> implements $PlanTemplateCopyWith<$Res> {
  factory _$PlanTemplateCopyWith(_PlanTemplate value, $Res Function(_PlanTemplate) _then) = __$PlanTemplateCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<int> days, bool active, List<PlanSlot> slots
});




}
/// @nodoc
class __$PlanTemplateCopyWithImpl<$Res>
    implements _$PlanTemplateCopyWith<$Res> {
  __$PlanTemplateCopyWithImpl(this._self, this._then);

  final _PlanTemplate _self;
  final $Res Function(_PlanTemplate) _then;

/// Create a copy of PlanTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? days = null,Object? active = null,Object? slots = null,}) {
  return _then(_PlanTemplate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<int>,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,slots: null == slots ? _self._slots : slots // ignore: cast_nullable_to_non_nullable
as List<PlanSlot>,
  ));
}


}

// dart format on
