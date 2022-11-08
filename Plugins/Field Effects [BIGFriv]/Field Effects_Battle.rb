#============================================================================
#
#
#
#============================================================================

#		FIELD EFFECTS IN ORDER OF NUMBER
#
#	1|	Forest Field
#	2|	Forest Fire Field
#	3|	Cave Field
#	4|	Flooded Cavern Field
#	5|	Water Surface Field
#	6|	Underwater Field
#	7|	Library Field

#
#		GENERAL CHANGES
#

# BUG TYPE SPEED BOOST ON [ FOREST FIRE FIELD ]
class Battle::Battler
	alias fieldEffectsSpeed_pbSpeed pbSpeed
	
	def pbSpeed
	speedMult *= 1.2 if pbHasType?(:BUG) && $PokemonTemp.fieldEffectsBg == 2 # Forest Fire Field
	
	fieldEffectsSpeed_pbSpeed
	end
end

#=============================================================================
# End Of Round end effects that apply to a battler
# Copy-paste code and do this later								TODO
#=============================================================================
#def pbEOREndBattlerEffects(priority)
	# Forest Fire burns Grass-Types after 3rd Turn on the field
	#pbEORCountDownBattlerEffect(priority, PBEffects::ForestFireGrass) { |battler|
	#  next if battler.fainted? || #AQUARING
    #  if battler.pbCanBurn?
    #    PBDebug.log("[Lingering effect] #{battler.pbThis} fell asleep because of Yawn")
    #    battler.pbBurn
    #  end
    #}
#end

# CANT BE FROZEN OR FROSTBITTEN [ FOREST FIRE FIELD ] 			TODO

# 30% chance Burn for Grass-Type Moves 
# def pbEffectsOnMakingHit(move, user, target)					TODO 


#==================================
# 		ABILITY CHANGES
#==================================

# SWARM

Battle::AbilityEffects::DamageCalcFromUser.add(:SWARM,
  proc { |ability, user, target, move, mults, baseDmg, type|
										# Forest Field 
    if (user.hp <= user.totalhp / 3 || $game_temp.fieldEffectsBg == 1) && type == :BUG
      mults[:attack_multiplier] *= 1.5
    end
  }
)

# OVERGROW

Battle::AbilityEffects::DamageCalcFromUser.add(:OVERGROW,
  proc { |ability, user, target, move, mults, baseDmg, type|
										# Forest Field
    if (user.hp <= user.totalhp / 3 || $game_temp.fieldEffectsBg == 1) && type == :GRASS
      mults[:attack_multiplier] *= 1.5
    end
  }
)

# GRASS PELT
Battle::AbilityEffects::DamageCalcFromTarget.add(:GRASSPELT,
  proc { |ability, user, target, move, mults, baseDmg, type|
															  # Forest Field
    if user.battle.field.terrain==PBBattleTerrains::Grassy || $game_temp.fieldEffectsBg == 1
      mults[:defense_multiplier] *= 2
    end
  }
)

# LEAF GUARD
Battle::AbilityEffects::StatusImmunity.add(:LEAFGUARD,
  proc { |ability, battler, status|
																		# Forest Field
    next true if [:Sun, :HarshSun].include?(battler.battle.pbWeather) || $game_temp.fieldEffectsBg==1
  }
)

# BLAZE
Battle::AbilityEffects::DamageCalcFromUser.add(:BLAZE,
  proc { |ability, user, target, move, mults, baseDmg, type|
										# Forest Fire Field 
    if (user.hp <= user.totalhp / 3 || $game_temp.fieldEffectsBg == 2) && type == :FIRE
      mults[:attack_multiplier] *= 1.5
    end
  }
)

# FLASH FIRE 
Battle::AbilityEffects::DamageCalcFromUser.add(:FLASHFIRE,
  proc { |ability, user, target, move, mults, baseDmg, type|
										      # Forest Fire Field 
    if (user.effects[PBEffects::FlashFire] || $game_temp.fieldEffectsBg == 2) && type == :FIRE
      mults[:attack_multiplier] *= 1.5
    end
  }
)

# FLARE BOOST
Battle::AbilityEffects::DamageCalcFromUser.add(:FLAREBOOST,
  proc { |ability, user, target, move, mults, baseDmg, type|
						# Forest Fire Field
    if (user.burned? || $game_temp.fieldEffectsBg == 2) && move.specialMove?
      mults[:base_damage_multiplier] *= 1.5
    end
  }
)

# MIMICRY
Battle::AbilityEffects::OnSwitchIn.add(:MIMICRY,
  proc { |ability, battler, battle, switch_in|
    next if battle.field.terrain == :None
	next if $game_temp.fieldEffectsBg == 0
    Battle::AbilityEffects.triggerOnTerrainChange(ability, battler, battle, false)
  }
)

Battle::AbilityEffects::OnTerrainChange.add(:MIMICRY,
  proc { |ability, battler, battle, ability_changed|
    if battle.field.terrain == :None
      # Revert to original typing
      battle.pbShowAbilitySplash(battler)
      battler.pbResetTypes
      battle.pbDisplay(_INTL("{1} changed back to its regular type!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
    else
      # Change to new typing
      terrain_hash = {
        :Electric => :ELECTRIC,
        :Grassy   => :GRASS,
        :Misty    => :FAIRY,
        :Psychic  => :PSYCHIC
      }
      new_type = terrain_hash[battle.field.terrain]
      new_type_name = nil
      if new_type
        type_data = GameData::Type.try_get(new_type)
        new_type = nil if !type_data
        new_type_name = type_data.name if type_data
      end
      if new_type
        battle.pbShowAbilitySplash(battler)
		if $game_temp.fieldEffectsBg > 0
			battler.types[0] = new_type
		else
			battler.types[1] = new_type
		end
        battle.pbDisplay(_INTL("{1}'s type changed to {2}!", battler.pbThis, new_type_name))
        battle.pbHideAbilitySplash(battler)
      end
    end
  }
)

# EFFECT SPORE
Battle::AbilityEffects::OnBeingHit.add(:EFFECTSPORE,
  proc { |ability, user, target, move, battle|
    # NOTE: This ability has a 30% chance of triggering, not a 30% chance of
    #       inflicting a status condition. It can try (and fail) to inflict a
    #       status condition that the user is immune to.
    next if !move.pbContactMove?(user)
	if $game_temp.fieldEffectsBg == 1 # Forest Field
	   next if battle.pbRandom(100) >= 60
	else
	   next if battle.pbRandom(100) >= 30
	end 
    r = battle.pbRandom(3)
    next if r == 0 && user.asleep?
    next if r == 1 && user.poisoned?
    next if r == 2 && user.paralyzed?
    battle.pbShowAbilitySplash(target)
    if user.affectedByPowder?(Battle::Scene::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      case r
      when 0
        if user.pbCanSleep?(target, Battle::Scene::USE_ABILITY_SPLASH)
          msg = nil
          if !Battle::Scene::USE_ABILITY_SPLASH
            msg = _INTL("{1}'s {2} made {3} fall asleep!", target.pbThis,
               target.abilityName, user.pbThis(true))
          end
          user.pbSleep(msg)
        end
      when 1
        if user.pbCanPoison?(target, Battle::Scene::USE_ABILITY_SPLASH)
          msg = nil
          if !Battle::Scene::USE_ABILITY_SPLASH
            msg = _INTL("{1}'s {2} poisoned {3}!", target.pbThis,
               target.abilityName, user.pbThis(true))
          end
          user.pbPoison(target, msg)
        end
      when 2
        if user.pbCanParalyze?(target, Battle::Scene::USE_ABILITY_SPLASH)
          msg = nil
          if !Battle::Scene::USE_ABILITY_SPLASH
            msg = _INTL("{1}'s {2} paralyzed {3}! It may be unable to move!",
               target.pbThis, target.abilityName, user.pbThis(true))
          end
          user.pbParalyze(target, msg)
        end
      end
    end
    battle.pbHideAbilitySplash(target)
  }
)

# LONG REACH
Battle::AbilityEffects::AccuracyCalcFromUser.add(:LONGREACH,
  proc { |ability, mods, user, target, move, type|
    mods[:accuracy_multiplier] *= 0.9 if $game_temp.fieldEffectsBg == 1
  }
)

class Battle
  #=============================================================================
  # End Of Round various healing effects
  #=============================================================================
  def pbEORHealingEffects(priority)
    # Aqua Ring
    priority.each do |battler|
      next if !battler.effects[PBEffects::AquaRing]
      next if !battler.canHeal?
      hpGain = battler.totalhp / 16
      hpGain = (hpGain * 1.3).floor if battler.hasActiveItem?(:BIGROOT)
      battler.pbRecoverHP(hpGain)
      pbDisplay(_INTL("Aqua Ring restored {1}'s HP!", battler.pbThis(true)))
    end
    # Ingrain
    priority.each do |battler|
      next if !battler.effects[PBEffects::Ingrain]
      next if !battler.canHeal?
	  if $game_temp.fieldEffectsBg == 1
		hpGain = battler.totalhp / 8
	  else
		hpGain = battler.totalhp / 16
	  end
      hpGain = (hpGain * 1.3).floor if battler.hasActiveItem?(:BIGROOT) 
      battler.pbRecoverHP(hpGain)
      pbDisplay(_INTL("{1} absorbed nutrients with its roots!", battler.pbThis))
    end
	# Sap Sipper
	priority.each do |battler|
		next if !battler.hasActiveAbility?(:SAPSIPPER)
		next if !battler.canHeal?
		next if !$game_temp.fieldEffectsBg == 1 # Forest Field
      hpGain = battler.totalhp / 16
      hpGain = (hpGain * 1.3).floor if battler.hasActiveItem?(:BIGROOT)
      battler.pbRecoverHP(hpGain)
      pbDisplay(_INTL("{1} drank tree sap to recover!", battler.pbThis))
    end
    # Leech Seed
    priority.each do |battler|
      next if battler.effects[PBEffects::LeechSeed] < 0
      next if !battler.takesIndirectDamage?
      recipient = @battlers[battler.effects[PBEffects::LeechSeed]]
      next if !recipient || recipient.fainted?
      pbCommonAnimation("LeechSeed", recipient, battler)
      battler.pbTakeEffectDamage(battler.totalhp / 8) { |hp_lost|
        recipient.pbRecoverHPFromDrain(hp_lost, battler,
                                       _INTL("{1}'s health is sapped by Leech Seed!", battler.pbThis))
        recipient.pbAbilitiesOnDamageTaken
      }
      recipient.pbFaint if recipient.fainted?
    end
  end
  
  #=============================================================================
  # End Of Round deal damage to trapped battlers
  #=============================================================================
  TRAPPING_MOVE_COMMON_ANIMATIONS = {
    :BIND        => "Bind",
    :CLAMP       => "Clamp",
    :FIRESPIN    => "FireSpin",
    :MAGMASTORM  => "MagmaStorm",
    :SANDTOMB    => "SandTomb",
    :WRAP        => "Wrap",
    :INFESTATION => "Infestation"
  }

  def pbEORTrappingDamage(battler)
    return if battler.fainted? || battler.effects[PBEffects::Trapping] == 0
    battler.effects[PBEffects::Trapping] -= 1
    move_name = GameData::Move.get(battler.effects[PBEffects::TrappingMove]).name
    if battler.effects[PBEffects::Trapping] == 0
      pbDisplay(_INTL("{1} was freed from {2}!", battler.pbThis, move_name))
      return
    end
    anim = TRAPPING_MOVE_COMMON_ANIMATIONS[battler.effects[PBEffects::TrappingMove]] || "Wrap"
    pbCommonAnimation(anim, battler)
    return if !battler.takesIndirectDamage?
    hpLoss = (Settings::MECHANICS_GENERATION >= 6) ? battler.totalhp / 8 : battler.totalhp / 16
    if @battlers[battler.effects[PBEffects::TrappingUser]].hasActiveItem?(:BINDINGBAND)
      hpLoss = (Settings::MECHANICS_GENERATION >= 6) ? battler.totalhp / 6 : battler.totalhp / 8
    end
	if @field.terrain == :Grassy && @battlers[battler.effects[PBEffects::TrappingMove]]==:INFESTATION
      hpLoss = battler.totalhp / 6
    end
    @scene.pbDamageAnimation(battler)
    battler.pbTakeEffectDamage(hpLoss, false) { |hp_lost|
      pbDisplay(_INTL("{1} is hurt by {2}!", battler.pbThis, move_name))
    }
  end
  
end

# Water Compaction
#BattleHandlers::EOREffectAbility.add(:WATERCOMPACTION,
#  proc { |ability,battler,battle|
    # A Pokémon's turnCount is 0 if it became active after the beginning of a
    # round
#    if battler.turnCount=>0 && battler.pbCanRaiseStatStage?(:DEFENSE,battler)
#      battler.pbRaiseStatStageByAbility(:DEFENSE,1,battler)
#    end
#  }
#)


#=================================
# Form Dependent Abilities
#=================================

class PokeBattle_Battler
# Checks the Pokémon's form and updates it if necessary. Used for when a
  # Pokémon enters battle (endOfRound=false) and at the end of each round
  # (endOfRound=true).
  def pbCheckForm(endOfRound=false)
    return if fainted? || @effects[PBEffects::Transform]
    # Form changes upon entering battle and when the weather changes
    pbCheckFormOnWeatherChange if !endOfRound
    # Form changes upon entering battle and when the terrain changes
    pbCheckFormOnTerrainChange if !endOfRound
    # Darmanitan - Zen Mode
    if isSpecies?(:DARMANITAN) && self.ability == :ZENMODE
      newForm = @form
      if @hp <= @totalhp/2
        if @form < 2
          newForm = @form + 2
        else
          newForm = @form - 2
        end
      end
      if newForm != @form
        @battle.pbShowAbilitySplash(self,true)
        pbChangeForm(newForm,_INTL("{1} triggered!",abilityName))
        @battle.pbHideAbilitySplash(self)
      end
    end
    # Minior - Shields Down
    if isSpecies?(:MINIOR) && self.ability == :SHIELDSDOWN
      if @hp>@totalhp/2   # Turn into Meteor form
        newForm = (@form>=7) ? @form-7 : @form
        if @form!=newForm
          @battle.pbShowAbilitySplash(self,true)
          @battle.pbHideAbilitySplash(self)
          pbChangeForm(newForm,_INTL("{1} deactivated!",abilityName))
        elsif !endOfRound
          @battle.pbDisplay(_INTL("{1} deactivated!",abilityName))
        end
      elsif @form<7   # Turn into Core form
        @battle.pbShowAbilitySplash(self,true)
        @battle.pbHideAbilitySplash(self)
        pbChangeForm(@form+7,_INTL("{1} activated!",abilityName))
      end
    end
    # Wishiwashi - Schooling
    if isSpecies?(:WISHIWASHI) && self.ability == :SCHOOLING
      if (@level>=20 && @hp>@totalhp/4) || $game_temp.fieldEffectsBg==3 || $game_temp.fieldEffectsBg==4 # Water Surface Field + Underwater Field
        if @form!=1
          @battle.pbShowAbilitySplash(self,true)
          @battle.pbHideAbilitySplash(self)
          pbChangeForm(1,_INTL("{1} formed a school!",pbThis))
        end
      elsif @form!=0
        @battle.pbShowAbilitySplash(self,true)
        @battle.pbHideAbilitySplash(self)
        pbChangeForm(0,_INTL("{1} stopped schooling!",pbThis))
      end
    end
    # Zygarde - Power Construct
    if isSpecies?(:ZYGARDE) && self.ability == :POWERCONSTRUCT && endOfRound
      if @hp<=@totalhp/2 && @form<2   # Turn into Complete Forme
        newForm = @form+2
        @battle.pbDisplay(_INTL("You sense the presence of many!"))
        @battle.pbShowAbilitySplash(self,true)
        @battle.pbHideAbilitySplash(self)
        pbChangeForm(newForm,_INTL("{1} transformed into its Complete Forme!",pbThis))
      end
    end
  end
end
#=================================

#=================================
# 			POWER BOOSTS
#=================================

class Battle::Move

alias fieldEffects_pbCalcDamageMultipliers pbCalcDamageMultipliers

  def pbCalcDamageMultipliers(user,target,numTargets,type,baseDmg,multipliers)
    # TYPES
    case $game_temp.fieldEffectsBg
		when 1 # Forest Field
		   if type == :GRASS
				  multipliers[:base_damage_multiplier] *= 1.5
				  @battle.pbDisplay(_INTL("The forestry energy strengthened the attack!")) #if $game_temp.fieldMessage==0
				  #$game_temp.fieldMessage += 1
		   end
		   if type == :BUG && specialMove?
				  multipliers[:base_damage_multiplier] *= 1.5
				  @battle.pbDisplay(_INTL("he attack spreads through the forest!")) #if $game_temp.fieldMessage==0
				  #$game_temp.fieldMessage += 1
		   end
		when 2 # Forest Fire Field
			if type == :FIRE
				  multipliers[:base_damage_multiplier] *= 1.5
				  @battle.pbDisplay(_INTL("The forest fire amplified the attack!")) #if $fieldMessages==0
				  #$fieldMessages += 1
		    end
			if type == :GRASS
				  multipliers[:base_damage_multiplier] *= 1.2
				  @battle.pbDisplay(_INTL("The burning forest strengthened the attack!")) #if $game_temp.fieldMessage==0
				  #$game_temp.fieldMessages += 1
		    end
			if type == :BUG
				  multipliers[:base_damage_multiplier] *= 1.1
				  @battle.pbDisplay(_INTL("The dying swarm takes its last stand!")) #if $game_temp.fieldMessage==0
				  #$game_temp.fieldMessage += 1
		    end
    end
	
	# MOVES 
	case $game_temp.fieldEffectsBg
		when 1 # Forest Field
		 # BOOSTS
		   if @id == :HURRICANE
              multipliers[:base_damage_multiplier] *= 2
			  @battle.pbDisplay(_INTL("Multiple trees fell on {1}!",target.pbThis(true)))
		   end
		   if @id == :ATTACKORDER
		      multipliers[:base_damage_multiplier] *= 1.5
			  @battle.pbDisplay(_INTL("The wild bugs joined the attack!"))
		   end
		   if @id == :GRAVAPPLE
		      multipliers[:base_damage_multiplier] *= 1.5
			  @battle.pbDisplay(_INTL("An apple fell from the tree!"))
		   end
		   if [:CUT, :PSYCHOCUT, :FURYCUTTER].include?(@id)
			 multipliers[:base_damage_multiplier] *= 1.5
		     @battle.pbDisplay(_INTL("A tree fell onto {1}!",target.pbThis(true)))
		   end     
		 # DEBUFFS
		   if [:ROCKTHROW].include?(@id)
		      multipliers[:base_damage_multiplier] *= 0.5
		      @battle.pbDisplay(_INTL("Some rocks hit the trees instead..."))
		   end
		   if [:MUDDYWATER, :SURF].include?(@id)
		      multipliers[:base_damage_multiplier] *= 0.5
		      @battle.pbDisplay(_INTL("The enemy used the trees to evade some damage..."))
		   end
		when 2 # Forest Fire Field
		   # BOOSTS
		   if [:HOGSBANEWHEEL].include?(@id)
		      multipliers[:base_damage_multiplier] *= 1.5
		      @battle.pbDisplay(_INTL("The hogsbane plants caught fire!"))
		   end
		   if [:WOODHAMMER].include?(@id)
		      multipliers[:base_damage_multiplier] *= 1.5
		      @battle.pbDisplay(_INTL("The wood was on fire!"))
		   end

     end
	fieldEffects_pbCalcDamageMultipliers(user,target,numTargets,type,baseDmg,multipliers)
  end
end


#==============================================================
# 				    MOVE - SPECIFIC CHANGES
#==============================================================

#============================
# GROWTH [ FOREST FIELD]
#============================
class Battle::Move::RaiseUserAtkSpAtk1Or2InSun < Battle::Move::MultiStatUpMove
  def initialize(battle, move)
    super
    @statUp = [:ATTACK, 1, :SPECIAL_ATTACK, 1]
  end

  def pbOnStartUse(user, targets)
    increment = 1
    increment = 2 if [:Sun, :HarshSun].include?(user.effectiveWeather) || $game_temp.fieldEffectsBg == 1 # Forest Field
    @statUp[1] = @statUp[3] = increment
  end
end

#============================
# DEFEND ORDER [ FOREST FIELD]
#============================
class Battle::Move::RaiseUserDefSpDef1 < Battle::Move::MultiStatUpMove
  def initialize(battle, move)
    super
	if @id == :DEFENDORDER 
	  if $game_temp.fieldEffectsBg == 1 # Forest Field
       @statUp = [:DEFENSE,2,:SPECIAL_DEFENSE,2] 
	  end
	else
	   @statUp = [:DEFENSE,1,:SPECIAL_DEFENSE,1]
	end
  end
end

#============================
# HEAL ORDER [ FOREST FIELD]
#============================
class Battle::Move::HealUserHalfOfTotalHP < Battle::Move::HealingMove
  def pbHealAmount(user)
	if @id == :HEALORDER 
		if $game_temp.fieldEffectsBg == 1 # Forest Field
			return (user.totalhp*0.66).round
		end
	else
		return (user.totalhp/2.0).round
	end
  end
end

#============================
# STRENGTH SAP [ FOREST FIELD]
#============================
class Battle::Move::HealUserByTargetAttackLowerTargetAttack1 < Battle::Move
  def healingMove?;  return true; end
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    # NOTE: The official games appear to just check whether the target's Attack
    #       stat stage is -6 and fail if so, but I've added the "fail if target
    #       has Contrary and is at +6" check too for symmetry. This move still
    #       works even if the stat stage cannot be changed due to an ability or
    #       other effect.
    if !@battle.moldBreaker && target.hasActiveAbility?(:CONTRARY) &&
       target.statStageAtMax?(:ATTACK)
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    elsif target.statStageAtMin?(:ATTACK)
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    # Calculate target's effective attack value
    stageMul = [2, 2, 2, 2, 2, 2, 2, 3, 4, 5, 6, 7, 8]
    stageDiv = [8, 7, 6, 5, 4, 3, 2, 2, 2, 2, 2, 2, 2]
    atk      = target.attack
    atkStage = target.stages[:ATTACK] + 6
    healAmt = (atk.to_f * stageMul[atkStage] / stageDiv[atkStage]).floor
    # Reduce target's Attack stat
    if target.pbCanLowerStatStage?(:ATTACK, user, self)
      target.pbLowerStatStage(:ATTACK, 1, user)
    end
    # Heal user
    if target.hasActiveAbility?(:LIQUIDOOZE)
      @battle.pbShowAbilitySplash(target)
      user.pbReduceHP(healAmt)
      @battle.pbDisplay(_INTL("{1} sucked up the liquid ooze!", user.pbThis))
      @battle.pbHideAbilitySplash(target)
      user.pbItemHPHealCheck
    elsif user.canHeal?
	  healAmt = (healAmt * 1.3).floor if $game_temp.fieldEffectsBg == 1 # Forest Field
      healAmt = (healAmt * 1.3).floor if user.hasActiveItem?(:BIGROOT)
      user.pbRecoverHP(healAmt)
      @battle.pbDisplay(_INTL("{1}'s HP was restored.", user.pbThis))
    end
  end
end

#============================
# INGRAIN [ FOREST FIRE FIELD]
#============================
class Battle::Move::StartHealUserEachTurnTrapUserInBattle < Battle::Move
  def canSnatch?; return true; end

  def pbMoveFailed?(user, targets)
    if user.effects[PBEffects::Ingrain]
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.effects[PBEffects::Ingrain] = true
    @battle.pbDisplay(_INTL("{1} planted its roots!", user.pbThis))
  end
  
  def pbAdditionalEffect(user, target)
    super
	if $game_temp.fieldEffectsBg == 2 # Forest Fire Field
	   user.pbBurn(user) if user.pbCanBurn?(user, false, self)
	   @statUp = [:SPEED, 1]
	end
  end
end

#============================
# WOOD HAMMER [ FOREST FIRE FIELD]
#============================
class Battle::Move::RecoilThirdOfDamageDealt < Battle::Move::RecoilMove
  def pbRecoilDamage(user, target)
    return (target.damageState.totalHPLost / 3.0).round
  end
  
  def pbAdditionalEffect(user, target)
    if @id == :WOODHAMMER
		if $game_temp.fieldEffectsBg == 2 # Forest Fire Field
		   user.pbBurn(user) if user.pbCanBurn?(user, false, self)
		end
	end
  end
end

#============================
# LEECH SEED [ FOREST FIRE FIELD]
#============================
class Battle::Move::StartLeechSeedTarget < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    if target.effects[PBEffects::LeechSeed] >= 0
      @battle.pbDisplay(_INTL("{1} evaded the attack!", target.pbThis)) if show_message
      return true
    end
    if target.pbHasType?(:GRASS)
      @battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true))) if show_message
      return true
    end
    return false
  end

  def pbMissMessage(user, target)
    @battle.pbDisplay(_INTL("{1} evaded the attack!", target.pbThis))
    return true
  end

  def pbEffectAgainstTarget(user, target)
    target.effects[PBEffects::LeechSeed] = user.index
    @battle.pbDisplay(_INTL("{1} was seeded!", target.pbThis))
	target.pbBurn(user) if target.pbCanBurn?(user, false, self) && $game_temp.fieldEffectsBg == 2 # Forest Fire Field
  end
end

#============================
# FOREST'S CURSE [ FOREST FIELD; FOREST FIRE FIELD ]
#============================
class Battle::Move::AddGrassTypeToTarget < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    if !GameData::Type.exists?(:GRASS) || target.pbHasType?(:GRASS) || !target.canChangeType?
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    target.effects[PBEffects::Type3] = :GRASS
    typeName = GameData::Type.get(:GRASS).name
    @battle.pbDisplay(_INTL("{1} transformed into the {2} type!", target.pbThis, typeName))
	case $game_temp.fieldEffectsBg
		when 1 # Forest Field
		  target.effects[PBEffects::LeechSeed] = user.index
          @battle.pbDisplay(_INTL("{1} was seeded!",target.pbThis))
		when 2 # Forest Fire Field
		  target.pbBurn(user) if target.pbCanBurn?(user,false,self)
	end
  end
end

#============================
# NATURE POWER [ ALL FIELDS]
#============================
class Battle::Move::UseMoveDependingOnEnvironment < Battle::Move
  def callsAnotherMove?; return true; end

  def pbOnStartUse(user, targets)
    # NOTE: It's possible in theory to not have the move Nature Power wants to
    #       turn into, but what self-respecting game wouldn't at least have Tri
    #       Attack in it?
    @npMove = :TRIATTACK
    case @battle.field.terrain
    when :Electric
      @npMove = :THUNDERBOLT if GameData::Move.exists?(:THUNDERBOLT)
    when :Grassy
      @npMove = :ENERGYBALL if GameData::Move.exists?(:ENERGYBALL)
    when :Misty
      @npMove = :MOONBLAST if GameData::Move.exists?(:MOONBLAST)
    when :Psychic
      @npMove = :PSYCHIC if GameData::Move.exists?(:PSYCHIC)
    else
      case $game_temp.fieldEffectsBg
       when 1 # Forest Field
           @npMove = :WOODHAMMER if GameData::Move.exists?(:WOODHAMMER)
	   when 2 # Forest  Fire Field
           @npMove = :WOODHAMMER if GameData::Move.exists?(:WOODHAMMER)
      end
    end
  end

  def pbEffectAgainstTarget(user, target)
    @battle.pbDisplay(_INTL("{1} turned into {2}!", @name, GameData::Move.get(@npMove).name))
    user.pbUseMoveSimple(@npMove, target.index)
  end
end

#============================
# CAMOUFLAGE [ ALL FIELDS]
#============================
class Battle::Move::SetUserTypesBasedOnEnvironment < Battle::Move
  def canSnatch?; return true; end

  def pbMoveFailed?(user, targets)
    if !user.canChangeType?
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    @newType = :NORMAL
    checkedTerrain = false
    case @battle.field.terrain
		when :Electric
		  if GameData::Type.exists?(:ELECTRIC)
			@newType = :ELECTRIC
			checkedTerrain = true
		  end
		when :Grassy
		  if GameData::Type.exists?(:GRASS)
			@newType = :GRASS
			checkedTerrain = true
		  end
		when :Misty
		  if GameData::Type.exists?(:FAIRY)
			@newType = :FAIRY
			checkedTerrain = true
		  end
		when :Psychic
		  if GameData::Type.exists?(:PSYCHIC)
			@newType = :PSYCHIC
			checkedTerrain = true
		  end
    end
	if !checkedTerrain
      case $game_temp.fieldEffectsBg
        when 1 # Forest Field
          @newType = :BUG
        when 2 # Forest Fire Field
		  @newType = :BUG
      end
    end
    @newType = :NORMAL if !GameData::Type.exists?(@newType)
    if !GameData::Type.exists?(@newType) || !user.pbHasOtherType?(@newType)
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
	if $game_temp.fieldEffectsBg > 0 # FIELDS
		user.types[0] = new_type
	else 							   # TERRAINS
		user.types[1] = new_type
	end
    typeName = GameData::Type.get(@newType).name
    @battle.pbDisplay(_INTL("{1}'s type changed to {2}!", user.pbThis, typeName))
  end
end
#============================


#============================
# SECRET POWER + HIDDEN POWER [ ALL FIELDS]
#============================

class Battle::Move::EffectDependsOnEnvironment < Battle::Move
  def flinchingMove?; return [6, 10, 12].include?(@secretPower); end

  def pbOnStartUse(user, targets)
    # NOTE: This is Gen 7's list plus some of Gen 6 plus a bit of my own.
    @secretPower = 0   # Body Slam, paralysis
    case @battle.field.terrain
    when :Electric
      @secretPower = 1   # Thunder Shock, paralysis
    when :Grassy
      @secretPower = 2   # Vine Whip, sleep
    when :Misty
      @secretPower = 3   # Fairy Wind, lower Sp. Atk by 1
    when :Psychic
      @secretPower = 4   # Confusion, lower Speed by 1
    else
      case $game_temp.fieldEffectsBg
      when 1 # Forest Field
        @secretPower = 2    # Vine Whip, Sleep
	  when 2 # Forest Fire Field
	    @secretPower = 10   # Incinerate, Burn
      end
    end
  end

  # NOTE: This intentionally doesn't use def pbAdditionalEffect, because that
  #       method is called per hit and this move's additional effect only occurs
  #       once per use, after all the hits have happened (two hits are possible
  #       via Parental Bond).
  def pbEffectAfterAllHits(user, target)
    return if target.fainted?
    return if target.damageState.unaffected || target.damageState.substitute
    chance = pbAdditionalEffectChance(user, target)
    return if @battle.pbRandom(100) >= chance
    case @secretPower
    when 2
      target.pbSleep if target.pbCanSleep?(user, false, self)
    when 10
      target.pbBurn(user) if target.pbCanBurn?(user, false, self)
    when 0, 1
      target.pbParalyze(user) if target.pbCanParalyze?(user, false, self)
    when 9
      target.pbFreeze if target.pbCanFreeze?(user, false, self)
    when 5
      if target.pbCanLowerStatStage?(:ATTACK, user, self)
        target.pbLowerStatStage(:ATTACK, 1, user)
      end
    when 14
      if target.pbCanLowerStatStage?(:DEFENSE, user, self)
        target.pbLowerStatStage(:DEFENSE, 1, user)
      end
    when 3
      if target.pbCanLowerStatStage?(:SPECIAL_ATTACK, user, self)
        target.pbLowerStatStage(:SPECIAL_ATTACK, 1, user)
      end
    when 4, 6, 12
      if target.pbCanLowerStatStage?(:SPEED, user, self)
        target.pbLowerStatStage(:SPEED, 1, user)
      end
    when 8
      if target.pbCanLowerStatStage?(:ACCURACY, user, self)
        target.pbLowerStatStage(:ACCURACY, 1, user)
      end
    when 7, 11, 13
      target.pbFlinch(user)
    end
  end

  def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    id = :BODYSLAM   # Environment-specific anim
    case @secretPower
    when 1  then id = :THUNDERSHOCK if GameData::Move.exists?(:THUNDERSHOCK)
    when 2  then id = :VINEWHIP if GameData::Move.exists?(:VINEWHIP)
    when 3  then id = :FAIRYWIND if GameData::Move.exists?(:FAIRYWIND)
    when 4  then id = :CONFUSIO if GameData::Move.exists?(:CONFUSION)
    when 5  then id = :WATERPULSE if GameData::Move.exists?(:WATERPULSE)
    when 6  then id = :MUDSHOT if GameData::Move.exists?(:MUDSHOT)
    when 7  then id = :ROCKTHROW if GameData::Move.exists?(:ROCKTHROW)
    when 8  then id = :MUDSLAP if GameData::Move.exists?(:MUDSLAP)
    when 9  then id = :ICESHARD if GameData::Move.exists?(:ICESHARD)
    when 10 then id = :INCINERATE if GameData::Move.exists?(:INCINERATE)
    when 11 then id = :SHADOWSNEAK if GameData::Move.exists?(:SHADOWSNEAK)
    when 12 then id = :GUST if GameData::Move.exists?(:GUST)
    when 13 then id = :SWIFT if GameData::Move.exists?(:SWIFT)
    when 14 then id = :PSYWAVE if GameData::Move.exists?(:PSYWAVE)
    end
    super
  end
end

#=================================
# Field Transformations
#=================================

class Battle::Battler

alias fieldEffectsStatus_pbUseMove pbUseMove

  def pbUseMove(choice, specialUsage = false)
  # NOTE: This is intentionally determined before a multi-turn attack can
  #       set specialUsage to true.
  skipAccuracyCheck = (specialUsage && choice[2]!=@battle.struggle)
  # Start using the move
  pbBeginTurn(choice)
  
  # Labels the move being used as "move"
    move = choice[2]
	return if !move   # if move was not chosen somehow
	# STATUS MOVES
	case $game_temp.fieldEffectsBg
		when 1 # Forest Field
		
		when 2 # Forest Fire Field
		if [:WATERSPORT, :RAINDANCE, :DAMPENEDTERRAIN].include?(move.id)
				$game_temp.fieldEffectsBg = 1 # Forest Field 
				@battle.scene.pbChangeBGSprite
				@battle.pbDisplay(_INTL("The water put out the fire!"))
		end
		when 3 # 
		
	end
	# DAMAGE DEALING MOVES
	case $game_temp.fieldEffectsBg
		when 1 # Forest Field
		if ![:Rain, :HeavyRain].include?(@battle.pbWeather)
		     if [:FIREPLEDGE, :FIREBLAST, :FLAMEBURST, :ERUPTION, :SEARINGSHOT, :BLASTBURN, :INCINERATE, :LAVAPLUME, :MINDBLOWN, :BURNUP, :BURNINGJEALOUSY].include?(move.id)
					$game_temp.fieldEffectsBg = 2 # Forest Fire 
					@battle.scene.pbChangeBGSprite
					@battle.pbDisplay(_INTL("The forest caught fire!"))
		     end
		end	 
		when 2 # Forest Fire Field 
		if [:SURF, :MUDDYWATER, :WATERSPOUT, :WATERPLEDGE, :ORIGINPULSE].include?(move.id)
			if pbFieldTryUseMove(choice,move,specialUsage,skipAccuracyCheck)
				$game_temp.fieldEffectsBg = 1 # Forest Field 
				@battle.scene.pbChangeBGSprite
				@battle.pbDisplay(_INTL("The water put out the fire!"))
			end
		end
		if [:HURRICANE].include?(move.id)
				$game_temp.fieldEffectsBg = 1 # Forest Field 
				@battle.scene.pbChangeBGSprite
				@battle.pbDisplay(_INTL("The strong wind put out the fire!"))
		end
	end
	fieldEffectsStatus_pbUseMove(choice,specialUsage=false)
  end
end