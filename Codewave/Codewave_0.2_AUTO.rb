## Codewave_0.2 -Tuned Resonators in C minor
## Coded by Nanomancer

define :stopwatch do |int=30, max=6|
  ## interval in seconds, max in mins
  count = 0
  while count / 60.0 < max
    count += int
    sleep int
    puts "Time: #{count / 60.0} Minutes"
  end
  puts "STOP!"
end


define :autosync do |id, num = 0|
  puts "Liveloop ID: #{id} | tick no: #{look(:as)}"
  return sync id if tick(:as) == num
end

define :autostop do |num = 8|
  return stop if look(:as) == num
end

define :mk_rand_scale do |scale, len = 8|
  rand_s = []
  len.times do
    rand_s << scale.choose
  end
  return rand_s.ring
end

#######################

use_bpm 60
set_volume! 3
set_sched_ahead_time! 3
use_cue_logging false
use_random_seed Time.now.usec # 100

#############  CLOCK  #####################

in_thread do
  stopwatch(30, 20)
end

##############  BASS  #########################

live_loop :pulsar do
  autosync(:pulse)
  puts "Pulsar"


  use_synth :growl
  cut = [55, 60, 65, 70, 75, 80, 85, 80, 75, 70, 65, 60].ring.tick(:cut)
  #notes = (knit :c3, 4, :ds3, 1, :b2, 1)
  #notes = (knit :c3, 2, :ds3, 1, :c3, 2, :b2, 1)
  notes = (knit :c3, 2, :ds3, 1, :c3, 1)
  with_fx :reverb, mix: 0.3, room: 0.3, amp: 1 do
    (notes.size * 2).times do
      play notes.tick, amp: 0.19, attack: 1.125, sustain: 1.25, release: 3, cutoff: cut, res: 0.2
      sleep 8
    end
  end
  cue :trans
  autostop(rrand_i 2, 6)
  sleep [8, 16, 24].choose
end

############## TUNED RESONATED DRONE  #########################
cue :drn

live_loop :drone do
  autosync(:drn)

  scl = scale(:c5, :harmonic_minor, num_octaves: 1)[0..4]
  # scl = chord([:c1, :c2, :c3].choose, :minor, num_octaves: 2)
  notes = mk_rand_scale(scl, 4)

  puts "Drone sequence: #{notes}"
  (notes.size * 2).times do
    frq = midi_to_hz(notes.tick)
    del = (1.0 / frq)# * 2
    with_fx :echo, amp: 1, mix: 1, phase: del, decay: 2 do
      sample :ambi_drone, attack: 0.6, pan: 0, amp: 0.8, rate: 0.5, cutoff: 117.5
      sleep 8
    end
  end
  cue :prb
  autostop(rrand_i 4, 8)
end

##############  TUNED RESONATED HUM  #########################

live_loop :probe do
  autosync(:prb)
  #notes = chord([:c1, :c2, :c3].choose, :minor, num_octaves: 2).shuffle
  #notes = scale(:c4, :harmonic_minor, num_octaves: 1).shuffle
  notes = (ring 60, 62, 63, 65, 68, 71, 72).shuffle
  puts "Probe sequence: #{notes}"

  vol = 1

  4.times do

    with_fx :reverb, mix: [0.5, 0.6, 0.7, 0.8].choose, room: [0.6, 0.7, 0.8].choose do
      with_fx :compressor, threshold:  0.4 do
        with_fx :lpf, res: 0.1, cutoff: [70, 75, 80, 85].choose do
          phase = [0.25, 0.5, 0.75, 1, 1.5, 2].choose
          puts "Probe AM: #{phase}"
          with_fx :slicer, mix: [1, 0.75, 0.5, 0.25].choose, smooth_up: phase * 0.5, smooth_down: phase * 0.125, phase: phase do

            frq = midi_to_hz(notes.tick)
            with_fx :echo, amp: 0.7, mix: 0.85, phase: 1.0 / frq, decay: 2 do
              sample :ambi_haunted_hum, beat_stretch: 4, pan: -0.75, amp: vol, rate: (ring -0.25, 0.5, 0.25).tick(:ambi)
            end
            sleep [16, 8, 16].ring.look(:ambi)

            frq = midi_to_hz(notes.tick)
            with_fx :echo, amp: 0.7, mix: 0.85, phase: 1.0 / frq, decay: 2 do
              sample :ambi_haunted_hum, beat_stretch: 4, pan: 0.75, amp: vol, rate: (ring 0.25, -0.5, -0.25).look(:ambi)
            end
            sleep [16, 8, 16].ring.look(:ambi)
          end
          cue :stc
          sleep [2, 4, 6, 8, 12, 16].choose
        end
      end
    end
  end
  autostop(2)
end

##############  TUNED RINGMOD / SYNTH  #########################

live_loop :transmission do

  autosync(:trans)
  use_synth :blade
  chd = chord(:c1, :minor, num_octaves: 2).shuffle
  scl = scale([:c4, :c5, :c6].choose, :harmonic_minor, num_octaves: 1)

  2.times do
    notes = mk_rand_scale(scl, 3)
    puts "Transmission sequence: #{notes}"
    slp = [[3,3,2], [6,6,4], [8,8,4], [8,8,4,1,2,4], [12,6,12]].choose.ring
    slp = [8,8,4,2,4].ring

    (slp.size * 2).times do
      att, sus, rel = slp.tick * 0.3, slp.look * 0.2, slp.look * 0.5
      phase = [0.25, 0.5, 0.75, 1].choose
      mod_frq = rdist(0.0125, 0.5) * midi_to_hz(chd.tick(:chd))
      puts "Transmission AM: #{phase} | Ring mod frq: #{mod_frq}"
      with_fx :echo, mix: 0.25, phase: 1.5, decay: 4 do
        with_fx :ring_mod, freq: mod_frq do
          with_fx :slicer, mix: [0.9, 0.5, 0.25, 0.125].choose, smooth_up: phase * 0.5, smooth_down: phase * 0.125, phase: phase do
            play notes.look, amp: 0.08, attack: att, sustain: sus, release: rel, cutoff: 85
            sleep slp.look
          end
        end
      end
      autostop(rrand_i 2, 4)
    end
  end
  sleep [4, 8, 12, 16, 32].choose
end

live_loop :static do
  autosync(:stc)
  puts "Static"
  with_fx :reverb, mix: 0.5, room: 0.5 do
    with_fx :bitcrusher, bits: [12, 14].choose, sample_rate: [4000, 8000, 12000].choose do
      phase = [0.5, 0.25, 0.75, 1].ring
      2.times do
        with_fx :slicer, smooth_up: 0.125, mix: 0.75, phase: phase.tick do
          puts "Static AM: #{phase.look}"
          sample :ambi_lunar_land, cutoff: 110, beat_stretch: 8, amp: 0.2, rate: (ring -1, -2, -0.5).look
          sleep [8, 4, 16].ring.look
          sample :ambi_lunar_land, cutoff: 110, beat_stretch: 8, amp: 0.2, rate: (ring 1, 2, 0.5).look
          sleep 16
        end
        cue :pulse
        sleep [12, 24, 32].choose
      end
    end
  end
  autostop(rrand_i 2, 4)
end