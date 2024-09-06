-- eggsrpls
--
-- eggs + rpls
--
-- version 1.0.0 @andrew
--
-- required: grid (any size)
--
-- documentation:
-- github.com/andr-ew/eggsrpls

--device globals

g = grid.connect()

local wide = g and g.device and g.device.cols >= 16 or false

--system libs

cs = require 'controlspec'
-- lfos = require 'lfo'

--git submodule libs

pattern_time = include 'lib/eggs/lib/pattern_time_extended/pattern_time_extended' --pattern_time fork
mute_group = include 'lib/eggs/lib/pattern_time_extended/mute_group'              --pattern_time mute groups
pattern_param_factory = include 'lib/eggs/lib/pattern_time_extended/params'       --pattern_time params

include 'lib/eggs/lib/crops/core'                                    --crops, a UI component framework
Grid = include 'lib/eggs/lib/crops/components/grid'
Enc = include 'lib/eggs/lib/crops/components/enc'
Key = include 'lib/eggs/lib/crops/components/key'
Screen = include 'lib/eggs/lib/crops/components/screen'
Produce = {}                                                --additional components for crops
Produce.grid = include 'lib/eggs/lib/produce/grid'
Produce.screen = include 'lib/eggs/lib/produce/screen'

keymap = include 'lib/eggs/lib/keymap/keymap'                        --patterning grid keyboard
Keymap = include 'lib/eggs/lib/keymap/ui'

tune = include 'lib/eggs/lib/tune/tune'                              --diatonic tuning lib
tunings, scale_groups = include 'lib/eggs/lib/tune/scales'
Tune = include 'lib/eggs/lib/tune/ui'

arqueggiator = include 'lib/eggs/lib/arqueggiator/arqueggiator'      --arqueggiation (arquencing) lib
Arqueggiator = include 'lib/eggs/lib/arqueggiator/ui'

patcher = include 'lib/eggs/lib/patcher/patcher'                     --modulation maxtrix
Patcher = include 'lib/eggs/lib/patcher/ui/using_map_key'            --mod matrix patching UI utilities

nb = include 'lib/eggs/lib/nb/lib/nb'                                --nb. totally normal include path nothing to see here

--script files (eggs)

eggs = include 'lib/eggs/lib/globals'                                --global variables & objects

eggs.engines = include 'lib/eggs/lib/engines'                        --DEFINE NEW ENGINES IN THIS FILE
eggs.setup = include 'lib/eggs/lib/setup'                            --setup functions
eggs.params = include 'lib/eggs/lib/params'                          --script params

destination = include 'lib/eggs/lib/destinations/destination'        --destination prototype
jf_dest = include 'lib/eggs/lib/destinations/jf'                     --just friends output
midi_dest = include 'lib/eggs/lib/destinations/midi'                 --midi output
engine_dest = include 'lib/eggs/lib/destinations/engine'             --engine output
nb_dest = include 'lib/eggs/lib/destinations/nb'                     --nb output
crow_dests = include 'lib/eggs/lib/destinations/crow'                --crow output

Components = include 'lib/eggs/lib/ui/components'                    --ui components
local Eggs = {}
local _ --haha very funny lua
_, Eggs.grid = include 'lib/eggs/lib/ui/grid'                      --grid UI
Eggs.norns = include 'lib/eggs/lib/ui/norns'                       --norns UI

--script files (rpls)

rpls = include 'lib/rpls/lib/globals'
Gfx = include 'lib/rpls/lib/ui/graphics'                             --screen graphics component
rpls.params = include 'lib/rpls/lib/params'                          --params & softcut functionality
Rpls = {}
Rpls.norns = include 'lib/rpls/lib/ui/norns'                          --norns UI component
_, Rpls.grid = include 'lib/rpls/lib/ui/grid'                            --grid UI

--eggsrpls tweaks

script_focus = 'rpls'

eggs.img_path = norns.state.lib..'eggs/lib/img/'

rpls.crow_outputs_enabled = false
rpls.grid_graphics = false

App = {}

function App.norns()
    local _eggs = Eggs.norns()
    local _rpls = Rpls.norns()

    return function()
        if script_focus == 'eggs' then
            _eggs()
        else
            _rpls()
        end
    end
end

function App.grid()
    local _eggs = Eggs.grid{ wide = wide }
    local _rpls = Rpls.grid{ wide = wide, y = 8 }

    return function()
        _eggs{
            focused = script_focus == 'eggs', rows = 5
        }
        _rpls{ focused = script_focus == 'rpls' }
    end
end

--setup (eggs + crow shared)

eggs.setup.destinations()
local add_actions = eggs.setup.modulation_sources()
local crow_add = eggs.setup.crow(add_actions)

--setup (rpls)
    
rpls.params.pre_init()

--params stuff pre-init (eggs)

params.action_read = eggs.params.action_read
params.action_write = eggs.params.action_write
params.action_delete = eggs.params.action_delete

params:add_separator('destination')
eggs.params.add_destination_params()

params:add_separator('sep_engine', 'engine')
eggs.params.add_engine_selection_param()

params:read(nil, true) --read a first time before init to check the engine
params:lookup_param('engine_eggs'):bang()

--create, connect UI components

_app = {
    grid = App.grid({ wide = wide }), 
    norns = App.norns()
}

crops.connect_enc(_app.norns)
crops.connect_key(_app.norns)
crops.connect_screen(_app.norns, 15)
    
--init/cleanup

function init()
    nb:init()
    
    --add params (eggs)
    eggs.params.add_all_track_params()

    --add params (rpls)
    rpls.params.add_softcut_params()

    --add params (shared)

    params:add_separator('patcher')
    params:add_group('assignments', #patcher.destinations)
    patcher.add_assignment_params(function() 
        crops.dirty.grid = true; crops.dirty.screen = true
    end)
    
    eggs.params.add_pset_params()

    --inits

    params:read()
    params:bang()
    
    crow_add()

    eggs.setup.init()
    
    rpls.params.post_init()

    crops.connect_grid(_app.grid, g, 240)
end

function cleanup()
    if params:string('autosave pset') == 'yes' then params:write() end
end
