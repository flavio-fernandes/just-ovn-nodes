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
    timeout      time.Duration = 1 * time.Millisecond
    handle1      *pcap.Handle
    handle2      *pcap.Handle
)

func processPackets(handleA *pcap.Handle, handleB *pcap.Handle) {
     packetSource := gopacket.NewPacketSource(handleA, handleA.LinkType())
     for packet := range packetSource.Packets() {
            // Process packet here
            fmt.Println(packet)

            rawBytes := packet.Data()
            err = handleB.WritePacketData(rawBytes)
            if err != nil {
               log.Fatal(err)
            }
     }
}

func main() {
    // Open device1
    handle1, err = pcap.OpenLive(device1, snapshot_len, promiscuous, timeout)
    if err != nil {log.Fatal(err) }
    defer handle1.Close()

    // Open device2
    handle2, err = pcap.OpenLive(device2, snapshot_len, promiscuous, timeout)
    if err != nil {log.Fatal(err) }
    defer handle2.Close()

    // Set filter
    var filter string = "not arp"
    err = handle1.SetBPFFilter(filter)
    if err != nil {log.Fatal(err) }
    err = handle2.SetBPFFilter(filter)
    if err != nil {log.Fatal(err) }

    go processPackets(handle1, handle2)
    processPackets(handle2, handle1)
}

