package main

import (
    "fmt"
    "github.com/google/gopacket"
    "github.com/google/gopacket/pcap"
    "log"
    "time"
)

var (
    device       string = "eth0"
    snapshot_len int32  = 1500
    promiscuous  bool   = true
    err          error
    timeout      time.Duration = pcap.BlockForever
    handle       *pcap.Handle
)

func processPackets(device string, handle *pcap.Handle) {
     packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
     for packet := range packetSource.Packets() {
            fmt.Printf("From %s: ", device)
            fmt.Println(packet)

            rawBytes := packet.Data()
            err = handle.WritePacketData(rawBytes)
            if err != nil { log.Fatal(err) }
     }
}

func main() {
    // Open device
    handle, err = pcap.OpenLive(device, snapshot_len, promiscuous, timeout)
    if err != nil { log.Fatal(err) }
    defer handle.Close()

    // Set filter to avoid packets we will not care about
    var filter string = "not multicast and not broadcast"
    err = handle.SetBPFFilter(filter)
    if err != nil { log.Fatal(err) }

    // Mirror packets coming from device
    processPackets(device, handle)
}

