// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'macros.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Macros {

 double get protein; double get carbs; double get fats; double get kcal;
/// Create a copy of Macros
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MacrosCopyWith<Macros> get copyWith => _$MacrosCopyWithImpl<Macros>(this as Macros, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Macros&&(identical(other.protein, protein) || other.protein == protein)&&(identical(other.carbs, carbs) || other.carbs == carbs)&&(identical(other.fats, fats) || other.fats == fats)&&(identical(other.kcal, kcal) || other.kcal == kcal));
}


@override
int get hashCode => Object.hash(runtimeType,protein,carbs,fats,kcal);

@override
String toString() {
  return 'Macros(protein: $protein, carbs: $carbs, fats: $fats, kcal: $kcal)';
}


}

/// @nodoc
abstract mixin class $MacrosCopyWith<$Res>  {
  factory $MacrosCopyWith(Macros value, $Res Function(Macros) _then) = _$MacrosCopyWithImpl;
@useResult
$Res call({
 double protein, double carbs, double fats, double kcal
});




}
/// @nodoc
class _$MacrosCopyWithImpl<$Res>
    implements $MacrosCopyWith<$Res> {
  _$MacrosCopyWithImpl(this._self, this._then);

  final Macros _self;
  final $Res Function(Macros) _then;

/// Create a copy of Macros
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? protein = null,Object? carbs = null,Object? fats = null,Object? kcal = null,}) {
  return _then(_self.copyWith(
protein: null == protein ? _self.protein : protein // ignore: cast_nullable_to_non_nullable
as double,carbs: null == carbs ? _self.carbs : carbs // ignore: cast_nullable_to_non_nullable
as double,fats: null == fats ? _self.fats : fats // ignore: cast_nullable_to_non_nullable
as double,kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [Macros].
extension MacrosPatterns on Macros {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Macros value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Macros() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Macros value)  $default,){
final _that = this;
switch (_that) {
case _Macros():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Macros value)?  $default,){
final _that = this;
switch (_that) {
case _Macros() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double protein,  double carbs,  double fats,  double kcal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Macros() when $default != null:
return $default(_that.protein,_that.carbs,_that.fats,_that.kcal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double protein,  double carbs,  double fats,  double kcal)  $default,) {final _that = this;
switch (_that) {
case _Macros():
return $default(_that.protein,_that.carbs,_that.fats,_that.kcal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double protein,  double carbs,  double fats,  double kcal)?  $default,) {final _that = this;
switch (_that) {
case _Macros() when $default != null:
return $default(_that.protein,_that.carbs,_that.fats,_that.kcal);case _:
  return null;

}
}

}

/// @nodoc


class _Macros extends Macros {
  const _Macros({this.protein = 0, this.carbs = 0, this.fats = 0, this.kcal = 0}): super._();
  

@override@JsonKey() final  double protein;
@override@JsonKey() final  double carbs;
@override@JsonKey() final  double fats;
@override@JsonKey() final  double kcal;

/// Create a copy of Macros
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MacrosCopyWith<_Macros> get copyWith => __$MacrosCopyWithImpl<_Macros>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Macros&&(identical(other.protein, protein) || other.protein == protein)&&(identical(other.carbs, carbs) || other.carbs == carbs)&&(identical(other.fats, fats) || other.fats == fats)&&(identical(other.kcal, kcal) || other.kcal == kcal));
}


@override
int get hashCode => Object.hash(runtimeType,protein,carbs,fats,kcal);

@override
String toString() {
  return 'Macros(protein: $protein, carbs: $carbs, fats: $fats, kcal: $kcal)';
}


}

/// @nodoc
abstract mixin class _$MacrosCopyWith<$Res> implements $MacrosCopyWith<$Res> {
  factory _$MacrosCopyWith(_Macros value, $Res Function(_Macros) _then) = __$MacrosCopyWithImpl;
@override @useResult
$Res call({
 double protein, double carbs, double fats, double kcal
});




}
/// @nodoc
class __$MacrosCopyWithImpl<$Res>
    implements _$MacrosCopyWith<$Res> {
  __$MacrosCopyWithImpl(this._self, this._then);

  final _Macros _self;
  final $Res Function(_Macros) _then;

/// Create a copy of Macros
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? protein = null,Object? carbs = null,Object? fats = null,Object? kcal = null,}) {
  return _then(_Macros(
protein: null == protein ? _self.protein : protein // ignore: cast_nullable_to_non_nullable
as double,carbs: null == carbs ? _self.carbs : carbs // ignore: cast_nullable_to_non_nullable
as double,fats: null == fats ? _self.fats : fats // ignore: cast_nullable_to_non_nullable
as double,kcal: null == kcal ? _self.kcal : kcal // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
