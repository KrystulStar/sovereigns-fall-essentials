#============================================================================
#
#
#
#============================================================================

module PBEffects
	Terrain = 13 # Change this to the last number of PBEffects + 1
end

class Game_Temp
    # Field Effects 
	attr_accessor :fieldEffectsBg
	attr_accessor :fieldOverride
	attr_accessor :tempField
	attr_accessor :fieldCounter
	attr_accessor :fieldCollapse
	attr_accessor :fieldBackup
    attr_accessor :fieldMessage
	# Terrains
	attr_accessor :terrainEffectsBg
	attr_accessor :terrainOverride
	attr_accessor :tempTerrain 
	attr_accessor :terrainCounter 
	attr_accessor :terrainCollapse 
	attr_accessor :TerrainBG
end

#==========================================================
# Define here all your backgrounds for each Field Effect
#
#==========================================================

class Battle::Scene
    module FieldEffects
    Files = {
        0 => { # indoor
            :battle_bg => "battlebgBurning.png",
            :base_0 => "playerbaseBurning.png",
            :base_1 => "enemybaseBurning.png"
        },
        1 => { # forest
            :battle_bg => "forest_bg.png",
            :base_0 => "forest_base0.png",
            :base_1 => "forest_base1.png"
        },
		2 => { # Forest Field Field
            :battle_bg => "forest_fire_bg.png",
            :base_0 => "forest_fire_base0.png",
            :base_1 => "forest_fire_base1.png"
        }
    };
	end

	def pbChangeBGSprite
		id = $game_temp.fieldEffectsBg
		if id && FieldEffects::Files.key?(id)
			files = FieldEffects::Files[id]
			root = "Graphics/Battlebacks/"
			@sprites["battle_bg"].setBitmap("#{root}/#{files[:battle_bg]}") 
			@sprites["base_0"].setBitmap("#{root}/#{files[:base_0]}") 
			@sprites["base_1"].setBitmap("#{root}/#{files[:base_1]}")  
		end
	end
end
#
# Battle Bases
#


#
#
#

class Battle::Scene
  def pbCreateBackdropSprites
    case @battle.time
    when 1; time = "eve"
    when 2; time = "night"
    end
	# Choose backdrop based on:
		# Field Effects 
		$game_temp.fieldOverride = 0
		$game_temp.tempField = 0
		$game_temp.fieldCounter = 0
		$game_temp.fieldCollapse = 0
		# Terrains 
		$game_temp.terrainOverride = 0
		$game_temp.tempTerrain = 0
		$game_temp.terrainCounter = 0
		$game_temp.terrainCollapse = 0
    # Put everything together into backdrop, bases and message bar filenames
    backdropFilename = @battle.backdrop
    baseFilename = @battle.backdrop
    baseFilename = sprintf("%s_%s", baseFilename, @battle.backdropBase) if @battle.backdropBase
    messageFilename = @battle.backdrop
    if time
      trialName = sprintf("%s_%s", backdropFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_bg"))
        backdropFilename = trialName
      end
      trialName = sprintf("%s_%s", baseFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_base0"))
        baseFilename = trialName
      end
      trialName = sprintf("%s_%s", messageFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_message"))
        messageFilename = trialName
      end
    end
    if !pbResolveBitmap(sprintf("Graphics/Battlebacks/" + baseFilename + "_base0")) &&
       @battle.backdropBase
      baseFilename = @battle.backdropBase
      if time
        trialName = sprintf("%s_%s", baseFilename, time)
        if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_base0"))
          baseFilename = trialName
        end
      end
    end
	# FIELD EFFECTS + TERRAINS
	if backdropFilename == "forest" || backdropFilename == "forest_night"
	  fieldbd = 1
	elsif backdropFilename == "forest_fire" || backdropFilename == "forest_fire_night"
	  fieldbd = 2
	elsif backdropFilename == "cave" || backdropFilename == "cave_night"
	  fieldbd = 3
	elsif backdropFilename == "flooded_cavern" || backdropFilename == "flooded_cavern_night"
	  fieldbd = 4
	elsif backdropFilename == "water" || backdropFilename == "water_night"
	  fieldbd = 5
	elsif backdropFilename == "underwater" || backdropFilename == "underwater_night"
	  fieldbd = 6
	elsif backdropFilename == "library" || backdropFilename == "library_night"
	  fieldbd = 7
	else
	  fieldbd = 0
	end
	#p backdropFilename
    # Apply graphics
	#$game_temp.terrainEffectsBg = terrainbd
    $game_temp.fieldEffectsBg = fieldbd
    $game_temp.fieldBackup = $game_temp.fieldEffectsBg   
	
	#if backdropFilename == "grass"
	#	  terrainbd = 1
	#	  $game_temp.TerrainBG = 1
	#	elsif backdropFilename == "burning"
	#	  terrainbd = 2
	#	  $game_temp.TerrainBG = 2
	
    #$game_temp.fieldEffectsBg = $game_temp.fieldOverride if $game_temp.fieldOverride != 0
    #backdrop = backdrop3 if backdrop3
	
    # Finalise filenames
    battleBG   = "Graphics/Battlebacks/" + backdropFilename + "_bg"
    playerBase = "Graphics/Battlebacks/" + baseFilename + "_base0"
    enemyBase  = "Graphics/Battlebacks/" + baseFilename + "_base1"
    messageBG  = "Graphics/Battlebacks/" + messageFilename + "_message"
    # Apply graphics
    bg = pbAddSprite("battle_bg", 0, 0, battleBG, @viewport)
    bg.z = 0
    bg = pbAddSprite("battle_bg2", -Graphics.width, 0, battleBG, @viewport)
    bg.z      = 0
    bg.mirror = true
    2.times do |side|
      baseX, baseY = Battle::Scene.pbBattlerPosition(side)
      base = pbAddSprite("base_#{side}", baseX, baseY,
                         (side == 0) ? playerBase : enemyBase, @viewport)
      base.z = 1
      if base.bitmap
        base.ox = base.bitmap.width / 2
        base.oy = (side == 0) ? base.bitmap.height : base.bitmap.height / 2
      end
    end
    cmdBarBG = pbAddSprite("cmdBar_bg", 0, Graphics.height - 96, messageBG, @viewport)
    cmdBarBG.z = 180
  end
 end

#
# Set the message that appears first in each Field Effect here
# 

class Battle
	def pbStartBattleCore
    # Set up the battlers on each side
    sendOuts = pbSetUpSides
    # Create all the sprites and play the battle intro animation
    @scene.pbStartBattle(self)
    # Show trainers on both sides sending out Pokémon
    pbStartBattleSendOut(sendOuts)
	# Field announcement
	case $game_temp.fieldEffectsBg
		when 1 # Forest Field
		 pbDisplay(_INTL("Trees surround the area!"))
		when 2 # Forest Fire Field
		 pbDisplay(_INTL("The forest is ablaze!"))
		when 3 # Cave Field
		 pbDisplay(_INTL("The cave echoes dully..."))
		when 4 # Flooded Cavern Field
		 pbDisplay(_INTL("Water drips from the ceiling..."))
		when 5 # Water Surface Field
		 pbDisplay(_INTL("The water surface is calm."))
		when 6 # Underwater Field
		 pbDisplay(_INTL("Blub blub..."))
		when 7 # Library Field
		 pbDisplay(_INTL("Pages flutter around!"))		
	end
    # Weather announcement
    weather_data = GameData::BattleWeather.try_get(@field.weather)
    pbCommonAnimation(weather_data.animation) if weather_data
    case @field.weather
    when :Sun         then pbDisplay(_INTL("The sunlight is strong."))
    when :Rain        then pbDisplay(_INTL("It is raining."))
    when :Sandstorm   then pbDisplay(_INTL("A sandstorm is raging."))
    when :Hail        then pbDisplay(_INTL("Hail is falling."))
    when :HarshSun    then pbDisplay(_INTL("The sunlight is extremely harsh."))
    when :HeavyRain   then pbDisplay(_INTL("It is raining heavily."))
    when :StrongWinds then pbDisplay(_INTL("The wind is strong."))
    when :ShadowSky   then pbDisplay(_INTL("The sky is shadowy."))
    end
    # Terrain announcement
    terrain_data = GameData::BattleTerrain.try_get(@field.terrain)
    pbCommonAnimation(terrain_data.animation) if terrain_data
    case @field.terrain
    when :Electric
      pbDisplay(_INTL("The terrain is hyper-charged!"))
    when :Grassy
      pbDisplay(_INTL("The terrain is in full bloom!"))
    when :Misty
      pbDisplay(_INTL("Mist is surrounding the terrain."))
    when :Psychic
      pbDisplay(_INTL("The terrain feels confusing."))
	# when :Scorched
	#  pbDisplay(_INTL("The terrain is burnt!"))
	# when :Dampened
	#  pbDisplay(_INTL("The terrain is filled with puddles."))
	# when :Corroded
	#  pbDisplay(_INTL("The terrain is ------!"))
	# when :Frosted
	#  pbDisplay(_INTL("The terrain is ------!"))
	# when :Rainbow
	#  pbDisplay(_INTL("The terrain is shimmering with colors!"))
	# when :Inverse
	#  pbDisplay(_INTL("!NODDEGAMDRIEW ot emocleW"))
    end
    # Abilities upon entering battle
    pbOnAllBattlersEnteringBattle
    # Main battle loop
    pbBattleLoop
  end
end