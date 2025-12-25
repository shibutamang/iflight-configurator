import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../utils/constants.dart';

class SerialService {
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription<Uint8List>? _subscription;
  final StreamController<Uint8List> _dataController = StreamController<Uint8List>.broadcast();
  
  Stream<Uint8List> get dataStream => _dataController.stream;
  bool get isConnected => _port != null && _port!.isOpen;
  
  List<String> getAvailablePorts() {
    try {
      return SerialPort.availablePorts;
    } catch (e) {
      return [];
    }
  }
  
  Future<bool> connect(String portName) async {
    try {
      if (_port != null && _port!.isOpen) {
        await disconnect();
      }
      
      _port = SerialPort(portName);
      
      // Open port FIRST, then configure
      if (!_port!.openReadWrite()) {
        return false;
      }
      
      // Configure AFTER opening
      final config = SerialPortConfig()
        ..baudRate = SerialConfig.baudRate
        ..bits = SerialConfig.dataBits
        ..stopBits = SerialConfig.stopBits
        ..parity = SerialPortParity.none
        ..setFlowControl(SerialPortFlowControl.none);
      
      _port!.config = config;
      
      // Drain any stale data in the buffer
      try {
        _port!.drain();
      } catch (_) {}
      
      // Small delay to let port stabilize
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Start listening for incoming data
      _reader = SerialPortReader(_port!);
      
      _subscription = _reader!.stream.listen(
        (data) {
          _dataController.add(data);
        },
        onError: (error) {
          _dataController.addError(error);
        },
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    _reader?.close();
    _reader = null;
    
    _port?.close();
    _port = null;
  }
  
  Future<bool> write(Uint8List data) async {
    if (!isConnected) {
      return false;
    }
    
    try {
      int bytesWritten = _port!.write(data);
      return bytesWritten == data.length;
    } catch (e) {
      return false;
    }
  }
  
  void dispose() {
    disconnect();
    _dataController.close();
  }
}
