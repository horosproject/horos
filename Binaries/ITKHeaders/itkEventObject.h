/*=========================================================================
 *
 *  Copyright Insight Software Consortium
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0.txt
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 *=========================================================================*/
#ifndef __itkEventObject_h
#define __itkEventObject_h

#include "itkIndent.h"

namespace itk
{
/** \class EventObject
 * \brief Abstraction of the Events used to communicating among filters
    and with GUIs.
 *
 * EventObject provides a standard coding for sending and receiving messages
 * indicating things like the initiation of processes, end of processes,
 * modification of filters.
 *
 * EventObjects form a hierarchy similar to the itk::ExceptionObject allowing
 * to factorize common events in a tree-like structure. Higher detail can
 * be assigned by users by subclassing existing itk::EventObjects.
 *
 * EventObjects are used by itk::Command and itk::Object for implementing the
 * Observer/Subject design pattern. Observers register their interest in
 * particular kinds of events produced by a specific itk::Object. This
 * mechanism decouples classes among them.
 *
 * As opposed to itk::Exception, itk::EventObject does not represent error
 * states, but simply flow of information allowing to trigger actions
 * as a consequence of changes occurring in state on some itk::Objects.
 *
 * itk::EventObject carries information in its own type, it relies on the
 * appropriate use of the RTTI (Run Time Type Information).
 *
 * A set of standard EventObjects is defined near the end of itkEventObject.h.
 *
 * \sa itk::Command
 * \sa itk::ExceptionObject
 *
 * \ingroup ITKSystemObjects
 * \ingroup ITKCommon
 */
class ITKCommon_EXPORT EventObject
{
public:
  /** Constructor and copy constructor.  Note that these functions will be
   * called when children are instantiated. */
  EventObject() {}

  EventObject(const EventObject &){}

  /** Virtual destructor needed  */
  virtual ~EventObject() {}

  /**  Create an Event of this type This method work as a Factory for
   *  creating events of each particular type. */
  virtual EventObject * MakeObject() const = 0;

  /** Print Event information.  This method can be overridden by
   * specific Event subtypes.  The default is to print out the type of
   * the event. */
  virtual void Print(std::ostream & os) const;

  /** Return the StringName associated with the event. */
  virtual const char * GetEventName(void) const = 0;

  /** Check if given event matches or derives from this event. */
  virtual bool CheckEvent(const EventObject *) const = 0;

protected:
  /** Methods invoked by Print() to print information about the object
   * including superclasses. Typically not called by the user (use Print()
   * instead) but used in the hierarchical print process to combine the
   * output of several classes.  */
  virtual void PrintSelf(std::ostream & os, Indent indent) const;

  virtual void PrintHeader(std::ostream & os, Indent indent) const;

  virtual void PrintTrailer(std::ostream & os, Indent indent) const;

private:
  typedef  EventObject *EventFactoryFunction ( );
  void operator=(const EventObject &);
};

/** Generic inserter operator for EventObject and its subclasses. */
inline std::ostream & operator<<(std::ostream & os, EventObject & e)
{
  ( &e )->Print(os);
  return os;
}


#define ITKEvent_EXPORT ITKCommon_EXPORT

/**
 *  Macro for creating new Events
 */
#define itkEventMacro(classname, super)                              \
  /** \class classname */                                            \
  class ITKEvent_EXPORT classname:public super                       \
  {                                                                  \
public:                                                              \
    typedef classname Self;                                          \
    typedef super     Superclass;                                    \
    classname() {}                                                   \
    virtual ~classname() {}                                          \
    virtual const char *GetEventName() const { return #classname; } \
    virtual bool CheckEvent(const::itk::EventObject * e) const       \
               { return ( dynamic_cast< const Self * >( e ) != NULL ); }         \
    virtual::itk::EventObject *MakeObject() const                    \
               { return new Self; }                                  \
    classname(const Self &s):super(s){};                             \
private:                                                             \
    void operator=(const Self &);                                    \
  };

/**
 *      Define some common ITK events
 */
itkEventMacro(NoEvent, EventObject)
itkEventMacro(AnyEvent, EventObject)
itkEventMacro(DeleteEvent, AnyEvent)
itkEventMacro(StartEvent, AnyEvent)
itkEventMacro(EndEvent, AnyEvent)
itkEventMacro(ProgressEvent, AnyEvent)
itkEventMacro(ExitEvent, AnyEvent)
itkEventMacro(AbortEvent, AnyEvent)
itkEventMacro(ModifiedEvent, AnyEvent)
itkEventMacro(InitializeEvent, AnyEvent)
itkEventMacro(IterationEvent, AnyEvent)
itkEventMacro(MultiResolutionIterationEvent,IterationEvent)
itkEventMacro(PickEvent, AnyEvent)
itkEventMacro(StartPickEvent, PickEvent)
itkEventMacro(EndPickEvent, PickEvent)
itkEventMacro(AbortCheckEvent, PickEvent)
itkEventMacro(FunctionEvaluationIterationEvent, IterationEvent)
itkEventMacro(GradientEvaluationIterationEvent, IterationEvent)
itkEventMacro(FunctionAndGradientEvaluationIterationEvent, IterationEvent)

itkEventMacro(UserEvent, AnyEvent)

#undef ITKEvent_EXPORT
#define ITKEvent_EXPORT ITK_ABI_EXPORT

} // end namespace itk

#endif
