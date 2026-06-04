// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MealSnapshot {

 String? get sourceMealTemplateId; String get name; List<MealTag> get tags; List<MealItem> get items;
/// Create a copy of MealSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MealSnapshotCopyWith<MealSnapshot> get copyWith => _$MealSnapshotCopyWithImpl<MealSnapshot>(this as MealSnapshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MealSnapshot&&(identical(other.sourceMealTemplateId, sourceMealTemplateId) || other.sourceMealTemplateId == sourceMealTemplateId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.items, items));
}


@override
int get hashCode => Object.hash(runtimeType,sourceMealTemplateId,name,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'MealSnapshot(sourceMealTemplateId: $sourceMealTemplateId, name: $name, tags: $tags, items: $items)';
}


}

/// @nodoc
abstract mixin class $MealSnapshotCopyWith<$Res>  {
  factory $MealSnapshotCopyWith(MealSnapshot value, $Res Function(MealSnapshot) _then) = _$MealSnapshotCopyWithImpl;
@useResult
$Res call({
 String? sourceMealTemplateId, String name, List<MealTag> tags, List<MealItem> items
});




}
/// @nodoc
class _$MealSnapshotCopyWithImpl<$Res>
    implements $MealSnapshotCopyWith<$Res> {
  _$MealSnapshotCopyWithImpl(this._self, this._then);

  final MealSnapshot _self;
  final $Res Function(MealSnapshot) _then;

/// Create a copy of MealSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceMealTemplateId = freezed,Object? name = null,Object? tags = null,Object? items = null,}) {
  return _then(_self.copyWith(
sourceMealTemplateId: freezed == sourceMealTemplateId ? _self.sourceMealTemplateId : sourceMealTemplateId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<MealTag>,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<MealItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [MealSnapshot].
extension MealSnapshotPatterns on MealSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MealSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MealSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MealSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _MealSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MealSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _MealSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? sourceMealTemplateId,  String name,  List<MealTag> tags,  List<MealItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MealSnapshot() when $default != null:
return $default(_that.sourceMealTemplateId,_that.name,_that.tags,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? sourceMealTemplateId,  String name,  List<MealTag> tags,  List<MealItem> items)  $default,) {final _that = this;
switch (_that) {
case _MealSnapshot():
return $default(_that.sourceMealTemplateId,_that.name,_that.tags,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? sourceMealTemplateId,  String name,  List<MealTag> tags,  List<MealItem> items)?  $default,) {final _that = this;
switch (_that) {
case _MealSnapshot() when $default != null:
return $default(_that.sourceMealTemplateId,_that.name,_that.tags,_that.items);case _:
  return null;

}
}

}

/// @nodoc


class _MealSnapshot extends MealSnapshot {
  const _MealSnapshot({this.sourceMealTemplateId, required this.name, final  List<MealTag> tags = const <MealTag>[], final  List<MealItem> items = const <MealItem>[]}): _tags = tags,_items = items,super._();
  

@override final  String? sourceMealTemplateId;
@override final  String name;
 final  List<MealTag> _tags;
@override@JsonKey() List<MealTag> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<MealItem> _items;
@override@JsonKey() List<MealItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of MealSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MealSnapshotCopyWith<_MealSnapshot> get copyWith => __$MealSnapshotCopyWithImpl<_MealSnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MealSnapshot&&(identical(other.sourceMealTemplateId, sourceMealTemplateId) || other.sourceMealTemplateId == sourceMealTemplateId)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._items, _items));
}


@override
int get hashCode => Object.hash(runtimeType,sourceMealTemplateId,name,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'MealSnapshot(sourceMealTemplateId: $sourceMealTemplateId, name: $name, tags: $tags, items: $items)';
}


}

/// @nodoc
abstract mixin class _$MealSnapshotCopyWith<$Res> implements $MealSnapshotCopyWith<$Res> {
  factory _$MealSnapshotCopyWith(_MealSnapshot value, $Res Function(_MealSnapshot) _then) = __$MealSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String? sourceMealTemplateId, String name, List<MealTag> tags, List<MealItem> items
});




}
/// @nodoc
class __$MealSnapshotCopyWithImpl<$Res>
    implements _$MealSnapshotCopyWith<$Res> {
  __$MealSnapshotCopyWithImpl(this._self, this._then);

  final _MealSnapshot _self;
  final $Res Function(_MealSnapshot) _then;

/// Create a copy of MealSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sourceMealTemplateId = freezed,Object? name = null,Object? tags = null,Object? items = null,}) {
  return _then(_MealSnapshot(
sourceMealTemplateId: freezed == sourceMealTemplateId ? _self.sourceMealTemplateId : sourceMealTemplateId // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<MealTag>,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<MealItem>,
  ));
}


}

// dart format on
