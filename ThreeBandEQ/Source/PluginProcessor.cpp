/*
  ==============================================================================

    ThreeBandEQ Processor Implementation
    
    This file contains the implementation of a 3-band equalizer.
    The processBlock method handles the audio processing for low, mid, and high bands.

  ==============================================================================
*/

#include "PluginProcessor.h"
#include "PluginEditor.h"

//==============================================================================
ThreeBandEQAudioProcessor::ThreeBandEQAudioProcessor()
#ifndef JucePlugin_PreferredChannelConfigurations
     : AudioProcessor (BusesProperties()
                     #if ! JucePlugin_IsMidiEffect
                      #if ! JucePlugin_IsSynth
                       .withInput  ("Input",  juce::AudioChannelSet::stereo(), true)
                      #endif
                       .withOutput ("Output", juce::AudioChannelSet::stereo(), true)
                     #endif
                       ),
#endif
    parameters(*this, nullptr, "PARAMETERS", createParameters())
{
}

ThreeBandEQAudioProcessor::~ThreeBandEQAudioProcessor()
{
}

//==============================================================================
const juce::String ThreeBandEQAudioProcessor::getName() const
{
    return JucePlugin_Name;
}

bool ThreeBandEQAudioProcessor::acceptsMidi() const
{
   #if JucePlugin_WantsMidiInput
    return true;
   #else
    return false;
   #endif
}

bool ThreeBandEQAudioProcessor::producesMidi() const
{
   #if JucePlugin_ProducesMidiOutput
    return true;
   #else
    return false;
   #endif
}

bool ThreeBandEQAudioProcessor::isMidiEffect() const
{
   #if JucePlugin_IsMidiEffect
    return true;
   #else
    return false;
   #endif
}

double ThreeBandEQAudioProcessor::getTailLengthSeconds() const
{
    return 0.0;
}

int ThreeBandEQAudioProcessor::getNumPrograms()
{
    return 1;
}

int ThreeBandEQAudioProcessor::getCurrentProgram()
{
    return 0;
}

void ThreeBandEQAudioProcessor::setCurrentProgram (int index)
{
    juce::ignoreUnused(index);
}

const juce::String ThreeBandEQAudioProcessor::getProgramName (int index)
{
    juce::ignoreUnused(index);
    return {};
}

void ThreeBandEQAudioProcessor::changeProgramName (int index, const juce::String& newName)
{
    juce::ignoreUnused(index, newName);
}

//==============================================================================
void ThreeBandEQAudioProcessor::prepareToPlay (double sampleRate, int samplesPerBlock)
{
    // Initialize DSP processing chain
    juce::dsp::ProcessSpec spec;
    spec.sampleRate = sampleRate;
    spec.maximumBlockSize = samplesPerBlock;
    spec.numChannels = getTotalNumOutputChannels();
    
    processorChain.prepare(spec);
    
    // Initialize filters with default settings
    updateFilters();
}

void ThreeBandEQAudioProcessor::releaseResources()
{
    // Called when playback stops or the audio device is closed
}

#ifndef JucePlugin_PreferredChannelConfigurations
bool ThreeBandEQAudioProcessor::isBusesLayoutSupported (const BusesLayout& layouts) const
{
  #if JucePlugin_IsMidiEffect
    juce::ignoreUnused (layouts);
    return true;
  #else
    // Only support stereo inputs and outputs
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

   #if ! JucePlugin_IsSynth
    if (layouts.getMainInputChannelSet() != layouts.getMainOutputChannelSet())
        return false;
   #endif

    return true;
  #endif
}
#endif

void ThreeBandEQAudioProcessor::processBlock (juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    juce::ScopedNoDenormals noDenormals;
    auto totalNumInputChannels  = getTotalNumInputChannels();
    auto totalNumOutputChannels = getTotalNumOutputChannels();

    // Clear any output channels that don't have input channels
    for (auto i = totalNumInputChannels; i < totalNumOutputChannels; ++i)
        buffer.clear (i, 0, buffer.getNumSamples());
    
    // Update the filters based on current parameters
    updateFilters();
    
    // Process audio through the filter chain
    block = juce::dsp::AudioBlock<float>(buffer);
    context = juce::dsp::ProcessContextReplacing<float>(block);
    processorChain.process(context);
    
    juce::ignoreUnused(midiMessages);
}

//==============================================================================
bool ThreeBandEQAudioProcessor::hasEditor() const
{
    return true;
}

juce::AudioProcessorEditor* ThreeBandEQAudioProcessor::createEditor()
{
    // Create a custom editor
    return new juce::GenericAudioProcessorEditor (*this);
    // Once you implement a custom editor:
    // return new ThreeBandEQAudioProcessorEditor (*this);
}

//==============================================================================
void ThreeBandEQAudioProcessor::getStateInformation (juce::MemoryBlock& destData)
{
    // Save parameters
    auto state = parameters.copyState();
    std::unique_ptr<juce::XmlElement> xml(state.createXml());
    copyXmlToBinary(*xml, destData);
}

void ThreeBandEQAudioProcessor::setStateInformation (const void* data, int sizeInBytes)
{
    // Restore parameters
    std::unique_ptr<juce::XmlElement> xmlState(getXmlFromBinary(data, sizeInBytes));
    if (xmlState.get() != nullptr && xmlState->hasTagName(parameters.state.getType()))
    {
        parameters.replaceState(juce::ValueTree::fromXml(*xmlState));
        updateFilters(); // Update filters with restored parameters
    }
}

//==============================================================================
// Update filter coefficients based on current parameter values
void ThreeBandEQAudioProcessor::updateFilters()
{
    auto& lowBand = processorChain.get<LowBand>();
    auto& midBand = processorChain.get<MidBand>();
    auto& highBand = processorChain.get<HighBand>();
    
    // Get current sample rate
    auto sampleRate = getSampleRate();
    
    // Get current parameter values
    float lowFreq = *parameters.getRawParameterValue("low_freq");
    float lowGain = *parameters.getRawParameterValue("low_gain");
    float midFreq = *parameters.getRawParameterValue("mid_freq");
    float midGain = *parameters.getRawParameterValue("mid_gain");
    float midQ = *parameters.getRawParameterValue("mid_q");
    float highFreq = *parameters.getRawParameterValue("high_freq");
    float highGain = *parameters.getRawParameterValue("high_gain");
    
    // Convert gain from dB to linear
    float lowGainLinear = juce::Decibels::decibelsToGain(lowGain);
    float midGainLinear = juce::Decibels::decibelsToGain(midGain);
    float highGainLinear = juce::Decibels::decibelsToGain(highGain);
    
    // Set filter coefficients
    // Low shelf filter
    *lowBand.state = *juce::dsp::IIR::Coefficients<float>::makeLowShelf(
        sampleRate, lowFreq, 0.7f, lowGainLinear);
    
    // Mid peak filter (with Q factor)
    *midBand.state = *juce::dsp::IIR::Coefficients<float>::makePeakFilter(
        sampleRate, midFreq, midQ, midGainLinear);
    
    // High shelf filter
    *highBand.state = *juce::dsp::IIR::Coefficients<float>::makeHighShelf(
        sampleRate, highFreq, 0.7f, highGainLinear);
}

//==============================================================================
// Create the parameter layout for the 3-band equalizer
juce::AudioProcessorValueTreeState::ParameterLayout ThreeBandEQAudioProcessor::createParameters()
{
    std::vector<std::unique_ptr<juce::RangedAudioParameter>> params;
    
    // Low band parameters
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        "low_freq", "Low Frequency", 20.0f, 500.0f, 200.0f));
    
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        "low_gain", "Low Gain", -24.0f, 24.0f, 0.0f));
    
    // Mid band parameters
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        "mid_freq", "Mid Frequency", 200.0f, 5000.0f, 1000.0f));
    
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        "mid_gain", "Mid Gain", -24.0f, 24.0f, 0.0f));
    
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        "mid_q", "Mid Q", 0.1f, 10.0f, 1.0f));
    
    // High band parameters
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        "high_freq", "High Frequency", 2000.0f, 20000.0f, 5000.0f));
    
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        "high_gain", "High Gain", -24.0f, 24.0f, 0.0f));
    
    return { params.begin(), params.end() };
}

//==============================================================================
// This creates the plugin instance
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new ThreeBandEQAudioProcessor();
}