// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/curly_block.dart';
import 'package:observatory/src/elements/field_ref.dart';
import 'package:observatory/src/elements/helpers/any_ref.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/src/elements/helpers/uris.dart';
import 'package:observatory/src/elements/sentinel_value.dart';

class InstanceRefElement extends HtmlElement implements Renderable {
  static const tag = const Tag<InstanceRefElement>('instance-ref-wrapped');

  RenderingScheduler<InstanceRefElement> _r;

  Stream<RenderedEvent<InstanceRefElement>> get onRendered => _r.onRendered;

  M.IsolateRef _isolate;
  M.InstanceRef _instance;
  M.InstanceRepository _instances;
  M.Instance _loadedInstance;
  bool _expanded = false;

  M.IsolateRef get isolate => _isolate;
  M.InstanceRef get instance => _instance;

  factory InstanceRefElement(M.IsolateRef isolate, M.InstanceRef instance,
      M.InstanceRepository instances, {RenderingQueue queue}) {
    assert(isolate != null);
    assert(instance != null);
    assert(instances != null);
    InstanceRefElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._instance = instance;
    e._instances = instances;
    return e;
  }

  InstanceRefElement.created() : super.created();

  @override
  void attached() {
    super.attached();
    _r.enable();
  }

  @override
  void detached() {
    super.detached();
    children = [];
    _r.disable(notify: true);
  }

  void render() {
    final content = _createLink();

    if (_hasValue()) {
      content.addAll([
        new SpanElement()..text = ' ',
        new CurlyBlockElement(expanded: _expanded, queue: _r.queue)
          ..children = [
            new DivElement()..classes = ['indent']
              ..children = _createValue()
          ]
          ..onToggle.listen((e) async {
            _expanded = e.control.expanded;
            if (_expanded) {
              e.control.disabled = true;
              await _refresh();
              e.control.disabled = false;
            }
          })
      ]);
    }

    children = content;
  }

  Future _refresh() async {
    _loadedInstance = await _instances.get(_isolate, _instance.id);
    _r.dirty();
  }

  List<Element> _createShowMoreButton() {
    if (_loadedInstance.count == null) {
      return [];
    }
    final count = _loadedInstance.count;
    final button = new ButtonElement()
      ..text = 'show next ${count}';
    button.onClick.listen((_) async {
      button.disabled = true;
      _loadedInstance = await _instances.get(_isolate, _instance.id,
                                             count: count * 2);
      _r.dirty();
    });
    return [button];
  }

  List<Element> _createLink() {
    switch (_instance.kind) {
      case M.InstanceKind.vNull:
      case M.InstanceKind.bool:
      case M.InstanceKind.int:
      case M.InstanceKind.double:
      case M.InstanceKind.float32x4:
      case M.InstanceKind.float64x2:
      case M.InstanceKind.int32x4:
        return [
          new AnchorElement(href: Uris.inspect(_isolate, object: _instance))
            ..text = _instance.valueAsString
        ];
      case M.InstanceKind.string:
        return [
          new AnchorElement(href: Uris.inspect(_isolate, object: _instance))
            ..text = asStringLiteral(_instance.valueAsString,
                _instance.valueAsStringIsTruncated)
        ];
      case M.InstanceKind.type:
      case M.InstanceKind.typeRef:
      case M.InstanceKind.typeParameter:
      case M.InstanceKind.boundedType:
        return [
          new AnchorElement(href: Uris.inspect(_isolate, object: _instance))
            ..text = _instance.name
        ];
      case M.InstanceKind.closure:
        return [
          new AnchorElement(href: Uris.inspect(_isolate, object: _instance))
            ..children = [
              new SpanElement()..classes = ['empathize']..text = 'Closure',
              new SpanElement()..text = _instance.closureFunction.name
            ]
        ];
      case M.InstanceKind.regExp:
        return [
          new AnchorElement(href: Uris.inspect(_isolate, object: _instance))
            ..children = [
              new SpanElement()..classes = ['empathize']
                ..text = _instance.clazz.name,
              new SpanElement()..text = _instance.pattern.name
            ]
        ];
      case M.InstanceKind.stackTrace:
        return [
          new AnchorElement(href: Uris.inspect(_isolate, object: _instance))
            ..text = _instance.clazz.name,
          new CurlyBlockElement(queue: _r.queue)
            ..children = [
              new DivElement()..classes = ['stackTraceBox']
                ..text = _instance.valueAsString
            ]
        ];
      case M.InstanceKind.plainInstance:
        return [
          new AnchorElement(href: Uris.inspect(_isolate, object: _instance))
            ..classes = ['empathize']
            ..text = _instance.clazz.name
        ];
      case M.InstanceKind.list:
      case M.InstanceKind.map:
      case M.InstanceKind.uint8ClampedList:
      case M.InstanceKind.uint8List:
      case M.InstanceKind.uint16List:
      case M.InstanceKind.uint32List:
      case M.InstanceKind.uint64List:
      case M.InstanceKind.int8List:
      case M.InstanceKind.int16List:
      case M.InstanceKind.int32List:
      case M.InstanceKind.int64List:
      case M.InstanceKind.float32List:
      case M.InstanceKind.float64List:
      case M.InstanceKind.int32x4List:
      case M.InstanceKind.float32x4List:
      case M.InstanceKind.float64x2List:
        return [
          new AnchorElement(href: Uris.inspect(_isolate, object: _instance))
            ..children = [
              new SpanElement()..classes = ['empathize']
                ..text = _instance.clazz.name,
              new SpanElement()..text = ' (${_instance.length})'
            ]
        ];
      case M.InstanceKind.mirrorReference:
        return [
          new AnchorElement(href: Uris.inspect(_isolate, object: _instance))
            ..classes = ['empathize']
            ..text = _instance.clazz.name
        ];
      case M.InstanceKind.weakProperty:
        return [
          new AnchorElement(href: Uris.inspect(_isolate, object: _instance))
            ..classes = ['empathize']
            ..text = _instance.clazz.name
        ];
    }
    throw new Exception('Unkown InstanceKind: ${_instance.kind}');
  }

  bool _hasValue() {
    switch (_instance.kind) {
      case M.InstanceKind.plainInstance:
      case M.InstanceKind.mirrorReference:
      case M.InstanceKind.weakProperty:
        return true;
      case M.InstanceKind.list:
      case M.InstanceKind.map:
      case M.InstanceKind.uint8ClampedList:
      case M.InstanceKind.uint8List:
      case M.InstanceKind.uint16List:
      case M.InstanceKind.uint32List:
      case M.InstanceKind.uint64List:
      case M.InstanceKind.int8List:
      case M.InstanceKind.int16List:
      case M.InstanceKind.int32List:
      case M.InstanceKind.int64List:
      case M.InstanceKind.float32List:
      case M.InstanceKind.float64List:
      case M.InstanceKind.int32x4List:
      case M.InstanceKind.float32x4List:
      case M.InstanceKind.float64x2List:
        return _instance.length > 0;
      default:
        return false;
    }
  }
  List<Element> _createValue() {
    if (_loadedInstance == null) {
      return [new SpanElement()..text = 'Loading...'];
    }
    switch (_instance.kind) {
      case M.InstanceKind.plainInstance:
        return _loadedInstance.fields.map((f) =>
          new DivElement()
            ..children = [
              new FieldRefElement(_isolate, f.decl, _instances,
                  queue: _r.queue),
              new SpanElement()..text = ' = ',
              f.value.isSentinel
                ? new SentinelValueElement(f.value.asSentinel, queue: _r.queue)
                : new InstanceRefElement(_isolate, f.value.asValue, _instances,
                    queue: _r.queue)
            ]).toList();
      case M.InstanceKind.list:
        var index = 0;
        return _loadedInstance.elements.map((e) =>
          new DivElement()
            ..children = [
              new SpanElement()..text = '[ ${index++} ] : ',
              e.isSentinel
                ? new SentinelValueElement(e.asSentinel, queue: _r.queue)
                : anyRef(_isolate, e.asValue, _instances, queue: _r.queue)
                // should be:
                // new InstanceRefElement(_isolate, e.asValue, _instances,
                //                        queue: _r.queue)
                // in some situations we obtain values that are not InstanceRef.
            ]).toList()..addAll(_createShowMoreButton());
      case M.InstanceKind.map:
        return _loadedInstance.associations.map((a) =>
          new DivElement()
            ..children = [
              new SpanElement()..text = '[ ',
              a.key.isSentinel
                ? new SentinelValueElement(a.key.asSentinel, queue: _r.queue)
                : new InstanceRefElement(_isolate, a.key.asValue, _instances,
                    queue: _r.queue),
              new SpanElement()..text = ' ] : ',
              a.value.isSentinel
                ? new SentinelValueElement(a.value.asSentinel, queue: _r.queue)
                : new InstanceRefElement(_isolate, a.value.asValue, _instances,
                    queue: _r.queue)
            ]).toList()..addAll(_createShowMoreButton());
      case M.InstanceKind.uint8ClampedList:
      case M.InstanceKind.uint8List:
      case M.InstanceKind.uint16List:
      case M.InstanceKind.uint32List:
      case M.InstanceKind.uint64List:
      case M.InstanceKind.int8List:
      case M.InstanceKind.int16List:
      case M.InstanceKind.int32List:
      case M.InstanceKind.int64List:
      case M.InstanceKind.float32List:
      case M.InstanceKind.float64List:
      case M.InstanceKind.int32x4List:
      case M.InstanceKind.float32x4List:
      case M.InstanceKind.float64x2List:
        var index = 0;
        return _loadedInstance.typedElements
          .map((e) => new DivElement()..text = '[ ${index++} ] : $e')
          .toList()..addAll(_createShowMoreButton());
      case M.InstanceKind.mirrorReference:
        return [
          new SpanElement()..text = '<referent> : ',
          new InstanceRefElement(_isolate, _loadedInstance.referent, _instances,
              queue: _r.queue)
        ];
      case M.InstanceKind.weakProperty:
        return [
          new SpanElement()..text = '<key> : ',
          new InstanceRefElement(_isolate, _loadedInstance.key, _instances,
              queue: _r.queue),
          new BRElement(),
          new SpanElement()..text = '<value> : ',
          new InstanceRefElement(_isolate, _loadedInstance.value, _instances,
            queue: _r.queue),
        ];
      default:
        return [];
    }
  }

  static String asStringLiteral(String value, [bool wasTruncated=false]) {
    var result = new List();
    result.add("'".codeUnitAt(0));
    for (int codeUnit in value.codeUnits) {
      if (codeUnit == '\n'.codeUnitAt(0)) result.addAll('\\n'.codeUnits);
      else if (codeUnit == '\r'.codeUnitAt(0)) result.addAll('\\r'.codeUnits);
      else if (codeUnit == '\f'.codeUnitAt(0)) result.addAll('\\f'.codeUnits);
      else if (codeUnit == '\b'.codeUnitAt(0)) result.addAll('\\b'.codeUnits);
      else if (codeUnit == '\t'.codeUnitAt(0)) result.addAll('\\t'.codeUnits);
      else if (codeUnit == '\v'.codeUnitAt(0)) result.addAll('\\v'.codeUnits);
      else if (codeUnit == '\$'.codeUnitAt(0)) result.addAll('\\\$'.codeUnits);
      else if (codeUnit == '\\'.codeUnitAt(0)) result.addAll('\\\\'.codeUnits);
      else if (codeUnit == "'".codeUnitAt(0)) result.addAll("'".codeUnits);
      else if (codeUnit < 32) {
         var escapeSequence = "\\u" + codeUnit.toRadixString(16).padLeft(4, "0");
         result.addAll(escapeSequence.codeUnits);
      } else result.add(codeUnit);
    }
    if (wasTruncated) {
      result.addAll("...".codeUnits);
    } else {
      result.add("'".codeUnitAt(0));
    }
    return new String.fromCharCodes(result);
  }
}
