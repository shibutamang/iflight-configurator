import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
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
      
      if (kDebugMode) {
        print('[SERIAL] Opening port: $portName');
      }
      
      _port = SerialPort(portName);
      
      // Open port FIRST, then configure
      if (!_port!.openReadWrite()) {
        if (kDebugMode) {
          print('[SERIAL] Failed to open port: ${SerialPort.lastError}');
        }
        return false;
      }
      
      if (kDebugMode) {
        print('[SERIAL] Port opened successfully');
      }
      
      // Configure AFTER opening
      final config = SerialPortConfig()
        ..baudRate = SerialConfig.baudRate
        ..bits = SerialConfig.dataBits
        ..stopBits = SerialConfig.stopBits
        ..parity = SerialPortParity.none
        ..setFlowControl(SerialPortFlowControl.none);
      
      _port!.config = config;
      
      // Verify config was applied
      final appliedConfig = _port!.config;
      if (kDebugMode) {
        print('[SERIAL] Config applied - Baud: ${appliedConfig.baudRate}, Bits: ${appliedConfig.bits}, Stop: ${appliedConfig.stopBits}, Parity: ${appliedConfig.parity}');
      }
      
      // Drain any stale data in the buffer
      try {
        _port!.drain();
      } catch (_) {}
      
      // Small delay to let port stabilize
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Start listening for incoming data
      _reader = SerialPortReader(_port!);
      if (kDebugMode) {
        print('[SERIAL] Reader created, starting to listen...');
      }
      
      _subscription = _reader!.stream.listen(
        (data) {
          if (kDebugMode) {
            final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
            print('[SERIAL] RX (${data.length} bytes): $hex');
          }
          _dataController.add(data);
        },
        onError: (error) {
          if (kDebugMode) {
            print('[SERIAL] RX Error: $error');
          }
          _dataController.addError(error);
        },
        onDone: () {
          if (kDebugMode) {
            print('[SERIAL] Reader stream closed');
          }
        },
      );
      
      if (kDebugMode) {
        print('[SERIAL] Connection complete, ready for communication');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[SERIAL] Connect error: $e');
      }
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
      if (kDebugMode) {
        print('[SERIAL] Write failed - not connected');
      }
      return false;
    }
    
    try {
      if (kDebugMode) {
        final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
        print('[SERIAL] TX (${data.length} bytes): $hex');
      }
      
      // write() returns number of bytes written
      int bytesWritten = _port!.write(data);
      
      if (kDebugMode) {
        print('[SERIAL] TX result: $bytesWritten of ${data.length} bytes written');
      }
      
      if (bytesWritten != data.length) {
        if (kDebugMode) {
          print('[SERIAL] WARNING: Not all bytes written!');
        }
        return false;
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[SERIAL] TX error: $e');
      }
      return false;
    }
  }
  
  void dispose() {
    disconnect();
    _dataController.close();
  }
}
