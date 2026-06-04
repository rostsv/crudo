// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Day {

 DateTime get date; String? get sourcePlanId; String? get planName; List<ScheduledMeal> get meals; double? get adherence; int? get thresholdUsed; DateTime? get lockedAt;
/// Create a copy of Day
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayCopyWith<Day> get copyWith => _$DayCopyWithImpl<Day>(this as Day, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Day&&(identical(other.date, date) || other.date == date)&&(identical(other.sourcePlanId, sourcePlanId) || other.sourcePlanId == sourcePlanId)&&(identical(other.planName, planName) || other.planName == planName)&&const DeepCollectionEquality().equals(other.meals, meals)&&(identical(other.adherence, adherence) || other.adherence == adherence)&&(identical(other.thresholdUsed, thresholdUsed) || other.thresholdUsed == thresholdUsed)&&(identical(other.lockedAt, lockedAt) || other.lockedAt == lockedAt));
}


@override
int get hashCode => Object.hash(runtimeType,date,sourcePlanId,planName,const DeepCollectionEquality().hash(meals),adherence,thresholdUsed,lockedAt);

@override
String toString() {
  return 'Day(date: $date, sourcePlanId: $sourcePlanId, planName: $planName, meals: $meals, adherence: $adherence, thresholdUsed: $thresholdUsed, lockedAt: $lockedAt)';
}


}

/// @nodoc
abstract mixin class $DayCopyWith<$Res>  {
  factory $DayCopyWith(Day value, $Res Function(Day) _then) = _$DayCopyWithImpl;
@useResult
$Res call({
 DateTime date, String? sourcePlanId, String? planName, List<ScheduledMeal> meals, double? adherence, int? thresholdUsed, DateTime? lockedAt
});




}
/// @nodoc
class _$DayCopyWithImpl<$Res>
    implements $DayCopyWith<$Res> {
  _$DayCopyWithImpl(this._self, this._then);

  final Day _self;
  final $Res Function(Day) _then;

/// Create a copy of Day
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? sourcePlanId = freezed,Object? planName = freezed,Object? meals = null,Object? adherence = freezed,Object? thresholdUsed = freezed,Object? lockedAt = freezed,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,sourcePlanId: freezed == sourcePlanId ? _self.sourcePlanId : sourcePlanId // ignore: cast_nullable_to_non_nullable
as String?,planName: freezed == planName ? _self.planName : planName // ignore: cast_nullable_to_non_nullable
as String?,meals: null == meals ? _self.meals : meals // ignore: cast_nullable_to_non_nullable
as List<ScheduledMeal>,adherence: freezed == adherence ? _self.adherence : adherence // ignore: cast_nullable_to_non_nullable
as double?,thresholdUsed: freezed == thresholdUsed ? _self.thresholdUsed : thresholdUsed // ignore: cast_nullable_to_non_nullable
as int?,lockedAt: freezed == lockedAt ? _self.lockedAt : lockedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Day].
extension DayPatterns on Day {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Day value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Day() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Day value)  $default,){
final _that = this;
switch (_that) {
case _Day():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Day value)?  $default,){
final _that = this;
switch (_that) {
case _Day() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  String? sourcePlanId,  String? planName,  List<ScheduledMeal> meals,  double? adherence,  int? thresholdUsed,  DateTime? lockedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Day() when $default != null:
return $default(_that.date,_that.sourcePlanId,_that.planName,_that.meals,_that.adherence,_that.thresholdUsed,_that.lockedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  String? sourcePlanId,  String? planName,  List<ScheduledMeal> meals,  double? adherence,  int? thresholdUsed,  DateTime? lockedAt)  $default,) {final _that = this;
switch (_that) {
case _Day():
return $default(_that.date,_that.sourcePlanId,_that.planName,_that.meals,_that.adherence,_that.thresholdUsed,_that.lockedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  String? sourcePlanId,  String? planName,  List<ScheduledMeal> meals,  double? adherence,  int? thresholdUsed,  DateTime? lockedAt)?  $default,) {final _that = this;
switch (_that) {
case _Day() when $default != null:
return $default(_that.date,_that.sourcePlanId,_that.planName,_that.meals,_that.adherence,_that.thresholdUsed,_that.lockedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Day extends Day {
   _Day({required this.date, this.sourcePlanId, this.planName, final  List<ScheduledMeal> meals = const <ScheduledMeal>[], this.adherence, this.thresholdUsed, this.lockedAt}): assert(date.isUtc, 'date must be the UTC-encoded local-date label'),assert(date.hour == 0 && date.minute == 0 && date.second == 0 && date.millisecond == 0 && date.microsecond == 0, 'date must be midnight-normalized'),assert((adherence == null) == (thresholdUsed == null) && (adherence == null) == (lockedAt == null), 'adherence, thresholdUsed and lockedAt are frozen together at lock'),assert(adherence == null || (adherence >= 0 && adherence <= 1), 'adherence must be within [0,1]'),assert(lockedAt == null || lockedAt.isUtc, 'lockedAt must be UTC'),_meals = meals,super._();
  

@override final  DateTime date;
@override final  String? sourcePlanId;
@override final  String? planName;
 final  List<ScheduledMeal> _meals;
@override@JsonKey() List<ScheduledMeal> get meals {
  if (_meals is EqualUnmodifiableListView) return _meals;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_meals);
}

@override final  double? adherence;
@override final  int? thresholdUsed;
@override final  DateTime? lockedAt;

/// Create a copy of Day
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayCopyWith<_Day> get copyWith => __$DayCopyWithImpl<_Day>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Day&&(identical(other.date, date) || other.date == date)&&(identical(other.sourcePlanId, sourcePlanId) || other.sourcePlanId == sourcePlanId)&&(identical(other.planName, planName) || other.planName == planName)&&const DeepCollectionEquality().equals(other._meals, _meals)&&(identical(other.adherence, adherence) || other.adherence == adherence)&&(identical(other.thresholdUsed, thresholdUsed) || other.thresholdUsed == thresholdUsed)&&(identical(other.lockedAt, lockedAt) || other.lockedAt == lockedAt));
}


@override
int get hashCode => Object.hash(runtimeType,date,sourcePlanId,planName,const DeepCollectionEquality().hash(_meals),adherence,thresholdUsed,lockedAt);

@override
String toString() {
  return 'Day(date: $date, sourcePlanId: $sourcePlanId, planName: $planName, meals: $meals, adherence: $adherence, thresholdUsed: $thresholdUsed, lockedAt: $lockedAt)';
}


}

/// @nodoc
abstract mixin class _$DayCopyWith<$Res> implements $DayCopyWith<$Res> {
  factory _$DayCopyWith(_Day value, $Res Function(_Day) _then) = __$DayCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, String? sourcePlanId, String? planName, List<ScheduledMeal> meals, double? adherence, int? thresholdUsed, DateTime? lockedAt
});




}
/// @nodoc
class __$DayCopyWithImpl<$Res>
    implements _$DayCopyWith<$Res> {
  __$DayCopyWithImpl(this._self, this._then);

  final _Day _self;
  final $Res Function(_Day) _then;

/// Create a copy of Day
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? sourcePlanId = freezed,Object? planName = freezed,Object? meals = null,Object? adherence = freezed,Object? thresholdUsed = freezed,Object? lockedAt = freezed,}) {
  return _then(_Day(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,sourcePlanId: freezed == sourcePlanId ? _self.sourcePlanId : sourcePlanId // ignore: cast_nullable_to_non_nullable
as String?,planName: freezed == planName ? _self.planName : planName // ignore: cast_nullable_to_non_nullable
as String?,meals: null == meals ? _self._meals : meals // ignore: cast_nullable_to_non_nullable
as List<ScheduledMeal>,adherence: freezed == adherence ? _self.adherence : adherence // ignore: cast_nullable_to_non_nullable
as double?,thresholdUsed: freezed == thresholdUsed ? _self.thresholdUsed : thresholdUsed // ignore: cast_nullable_to_non_nullable
as int?,lockedAt: freezed == lockedAt ? _self.lockedAt : lockedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
