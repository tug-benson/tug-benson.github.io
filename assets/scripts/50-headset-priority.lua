-- Give a high priority to the USB headset
rule = {
  matches = {
    {
      { "node.name", "equals", "alsa_output.usb-Synaptics_HUAWEI_USB-C_HEADSET_0296B2922211617299309149313C3-00.analog-stereo" },
    },
  },
  apply_properties = {
    ["device.priority"] = 2000,
  },
}
table.insert(wireplumber_config, rule)

-- Give a lower priority to the internal speakers
rule2 = {
  matches = {
    {
      { "node.name", "equals", "alsa_output.pci-0000_00_1f.3.analog-stereo" },
    },
  },
  apply_properties = {
    ["device.priority"] = 1000,
  },
}
table.insert(wireplumber_config, rule2)
