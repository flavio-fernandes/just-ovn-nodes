package main

import (
    "fmt"
    "github.com/google/gopacket"
    "github.com/google/gopacket/pcap"
    "log"
    "time"
)

var (
    device1      string = "eth0"
    device2      string = "eth1"
    snapshot_len int32  = 1500
    promiscuous  bool   = true
    err          error
    timeout      time.Duration = pcap.BlockForever
    handle1      *pcap.Handle
    handle2      *pcap.Handle
)

func processPackets(inputDevice string, handleA *pcap.Handle, handleB *pcap.Handle) {
     packetSource := gopacket.NewPacketSource(handleA, handleA.LinkType())
     for packet := range packetSource.Packets() {
            fmt.Printf("From %s: ", inputDevice)
            fmt.Println(packet)

            rawBytes := packet.Data()
            err = handleB.WritePacketData(rawBytes)
            if err != nil { log.Fatal(err) }
     }
}

func main() {
    // Open device1
    handle1, err = pcap.OpenLive(device1, snapshot_len, promiscuous, timeout)
    if err != nil { log.Fatal(err) }
    defer handle1.Close()

    // Open device2
    handle2, err = pcap.OpenLive(device2, snapshot_len, promiscuous, timeout)
    if err != nil { log.Fatal(err) }
    defer handle2.Close()

    // Set filter to avoid packets we will not care about
    var filter string = "not multicast and not broadcast"
    err = handle1.SetBPFFilter(filter)
    if err != nil { log.Fatal(err) }
    err = handle2.SetBPFFilter(filter)
    if err != nil { log.Fatal(err) }

    // Mirror packets coming from device1 to device2
    go processPackets(device1, handle1, handle2)

    // Mirror packets coming from device2 to device1
    processPackets(device2, handle2, handle1)
}

