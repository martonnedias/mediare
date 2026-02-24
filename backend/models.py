

from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Float, Boolean, Text
from sqlalchemy.orm import relationship
try:
    from .database import Base
except ImportError:
    from database import Base

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=False)
    cpf = Column(String, nullable=True)  # Preenchido no onboarding
    profile_picture = Column(String, nullable=True)
    family_unit_id = Column(Integer, nullable=True) # Current active family
    onboarding_completed = Column(Boolean, default=False)
    resguardo_active = Column(Boolean, default=False)
    families = relationship("FamilyMember", back_populates="user")
    deleted_at = Column(DateTime, nullable=True)

class FamilyUnit(Base):
    __tablename__ = 'family_units'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    mode = Column(String, nullable=False)  # collaborative, unilateral, gamification_only
    values_profile = Column(String, nullable=True) # conservative, religious, liberal, etc.
    members = relationship("FamilyMember", back_populates="family")
    locations = relationship("Location", back_populates="family")
    deleted_at = Column(DateTime, nullable=True)

class FamilyMember(Base):
    __tablename__ = 'family_members'
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    family_id = Column(Integer, ForeignKey('family_units.id'))
    role = Column(String, nullable=False)  # parent, child, etc.
    family = relationship("FamilyUnit", back_populates="members")
    user = relationship("User", back_populates="families")
    deleted_at = Column(DateTime, nullable=True)

class Child(Base):
    __tablename__ = 'children'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    cpf = Column(String, nullable=False)
    birth_date = Column(DateTime, nullable=False)
    interests = Column(String, nullable=True) # JSON ou lista separada por virgulas
    family_id = Column(Integer, ForeignKey('family_units.id'))
    deleted_at = Column(DateTime, nullable=True)

class Location(Base):
    __tablename__ = 'locations'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    type = Column(String, nullable=False)  # Casa Pai, Casa Mãe, Escola, etc.
    address = Column(String, nullable=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    family_unit_id = Column(Integer, ForeignKey('family_units.id'))
    family = relationship("FamilyUnit", back_populates="locations")

class LocationUsageHistory(Base):
    __tablename__ = 'location_usage_history'
    id = Column(Integer, primary_key=True, index=True)
    location_id = Column(Integer, ForeignKey('locations.id'))
    timestamp = Column(DateTime, nullable=False)
    event_type = Column(String, nullable=False)  # Check-in, compromisso, etc.
    family_unit_id = Column(Integer, ForeignKey('family_units.id'))
    family = relationship("FamilyUnit")

class CustodyCalendarRule(Base):
    __tablename__ = 'custody_calendar_rules'
    id = Column(Integer, primary_key=True, index=True)
    family_unit_id = Column(Integer, ForeignKey('family_units.id'))
    child_id = Column(Integer, ForeignKey('children.id'))
    rule_description = Column(String, nullable=False)
    start_time = Column(DateTime, nullable=False)
    end_time = Column(DateTime, nullable=False)
    family = relationship("FamilyUnit")
    child = relationship("Child")

class CustodyEvent(Base):
    __tablename__ = 'custody_events'
    id = Column(Integer, primary_key=True, index=True)
    family_unit_id = Column(Integer, ForeignKey('family_units.id'))
    child_id = Column(Integer, ForeignKey('children.id'))
    event_date = Column(DateTime, nullable=False)
    status = Column(String, nullable=False)  # on_time, late, etc.
    description = Column(String, nullable=True)
    location_id = Column(Integer, ForeignKey('locations.id'), nullable=True)
    family = relationship("FamilyUnit")
    child = relationship("Child")
    location = relationship("Location")
    checkins = relationship("CheckIn", back_populates="event", cascade="all, delete-orphan")

class CheckIn(Base):
    __tablename__ = 'checkins'
    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(Integer, ForeignKey('custody_events.id'))
    timestamp = Column(DateTime, nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    status = Column(String, nullable=False)  # on_time, late, etc.
    event = relationship("CustodyEvent", back_populates="checkins")

class Expense(Base):
    __tablename__ = 'expenses'
    id = Column(Integer, primary_key=True, index=True)
    description = Column(String, nullable=False)
    amount = Column(Float, nullable=False)
    attachment_url = Column(String, nullable=True)
    attachment_hash_sha256 = Column(String, nullable=True)
    family_unit_id = Column(Integer, ForeignKey('family_units.id'))
    child_id = Column(Integer, ForeignKey('children.id'))
    status = Column(String, nullable=False, default='Pendente')
    created_at = Column(DateTime, nullable=False)
    family = relationship("FamilyUnit")
    child = relationship("Child")
    deleted_at = Column(DateTime, nullable=True)

class ExpenseShare(Base):
    __tablename__ = 'expense_shares'
    id = Column(Integer, primary_key=True, index=True)
    expense_id = Column(Integer, ForeignKey('expenses.id'))
    user_id = Column(Integer, ForeignKey('users.id'))
    share_percentage = Column(Float, nullable=False)
    amount = Column(Float, nullable=False)
    expense = relationship("Expense")
    user = relationship("User")

class Budget(Base):
    __tablename__ = 'budgets'
    id = Column(Integer, primary_key=True, index=True)
    description = Column(String, nullable=False)
    estimated_value = Column(Float, nullable=False)
    status = Column(String, nullable=False, default='proposed')  # proposed, approved, rejected, canceled
    child_id = Column(Integer, ForeignKey('children.id'), nullable=True)
    family_unit_id = Column(Integer, ForeignKey('family_units.id'))
    created_at = Column(DateTime, nullable=False)
    family = relationship("FamilyUnit")
    child = relationship("Child")
    deleted_at = Column(DateTime, nullable=True)

class BudgetAnalysis(Base):
    __tablename__ = 'budget_analyses'
    id = Column(Integer, primary_key=True, index=True)
    budget_id = Column(Integer, ForeignKey('budgets.id'))
    analysis_text = Column(String, nullable=False)
    suggested_action = Column(String, nullable=True) # approve, negotiate, reject
    created_at = Column(DateTime, nullable=False)
    budget = relationship("Budget")

class BudgetNegotiation(Base):
    __tablename__ = 'budget_negotiations'
    id = Column(Integer, primary_key=True, index=True)
    budget_id = Column(Integer, ForeignKey('budgets.id'))
    user_id = Column(Integer, ForeignKey('users.id'))
    counter_offer = Column(Float, nullable=True)
    comment = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False)
    budget = relationship("Budget")
    user = relationship("User")

class FamilyChat(Base):
    __tablename__ = 'family_chats'
    id = Column(Integer, primary_key=True, index=True)
    family_unit_id = Column(Integer, ForeignKey('family_units.id'))
    created_at = Column(DateTime, nullable=False)
    family = relationship("FamilyUnit")

class ChatMessage(Base):
    __tablename__ = 'chat_messages'
    id = Column(Integer, primary_key=True, index=True)
    chat_id = Column(Integer, ForeignKey('family_chats.id'))
    sender_id = Column(Integer, ForeignKey('users.id'))
    content = Column(String, nullable=False)
    toxicity_score = Column(Float, nullable=False)
    sentiment_score = Column(Float, nullable=False)
    moderation_status = Column(String, nullable=False)  # allowed, blocked, needs_rewrite
    created_at = Column(DateTime, nullable=False)
    chat = relationship("FamilyChat")
    sender = relationship("User")

class ChatMessageRead(Base):
    __tablename__ = 'chat_message_reads'
    id = Column(Integer, primary_key=True, index=True)
    message_id = Column(Integer, ForeignKey('chat_messages.id'))
    user_id = Column(Integer, ForeignKey('users.id'))
    read_at = Column(DateTime, nullable=False)
    message = relationship("ChatMessage")
    user = relationship("User")

class Task(Base):
    __tablename__ = 'tasks'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)
    points = Column(Integer, nullable=False)
    child_id = Column(Integer, ForeignKey('children.id'))
    family_unit_id = Column(Integer, ForeignKey('family_units.id'))
    status = Column(String, nullable=False, default='pending')  # pending, completed, approved
    created_at = Column(DateTime, nullable=False)
    child = relationship("Child")
    family = relationship("FamilyUnit")
    deleted_at = Column(DateTime, nullable=True)

class Reward(Base):
    __tablename__ = 'rewards'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    description = Column(String, nullable=True)
    points_required = Column(Integer, nullable=False)
    family_unit_id = Column(Integer, ForeignKey('family_units.id'))
    created_at = Column(DateTime, nullable=False)
    family = relationship("FamilyUnit")
    deleted_at = Column(DateTime, nullable=True)

class ChildPointsLedger(Base):
    __tablename__ = 'child_points_ledger'
    id = Column(Integer, primary_key=True, index=True)
    child_id = Column(Integer, ForeignKey('children.id'))
    points = Column(Integer, nullable=False)
    description = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False)
    child = relationship("Child")

class ChildLevel(Base):
    __tablename__ = 'child_levels'
    id = Column(Integer, primary_key=True, index=True)
    child_id = Column(Integer, ForeignKey('children.id'))
    level = Column(Integer, nullable=False, default=1)
    points = Column(Integer, nullable=False, default=0)
    child = relationship("Child")

class Appointment(Base):
    __tablename__ = 'appointments'
    id = Column(Integer, primary_key=True, index=True)
    type = Column(String, nullable=False)  # passeio, viagem, consulta, etc.
    description = Column(String, nullable=True)
    scheduled_time = Column(DateTime, nullable=False)
    actual_time = Column(DateTime, nullable=True)
    status = Column(String, nullable=False, default='scheduled')  # scheduled, confirmed, in_progress, completed, late, canceled, etc.
    location_id = Column(Integer, ForeignKey('locations.id'), nullable=True)
    family_unit_id = Column(Integer, ForeignKey('family_units.id'))
    created_at = Column(DateTime, nullable=False)
    family = relationship("FamilyUnit")
    location = relationship("Location")
    deleted_at = Column(DateTime, nullable=True)

class AppointmentChecklist(Base):
    __tablename__ = 'appointment_checklists'
    id = Column(Integer, primary_key=True, index=True)
    appointment_id = Column(Integer, ForeignKey('appointments.id'))
    item_description = Column(String, nullable=False)
    appointment = relationship("Appointment")

class AppointmentChecklistStatus(Base):
    __tablename__ = 'appointment_checklist_status'
    id = Column(Integer, primary_key=True, index=True)
    checklist_id = Column(Integer, ForeignKey('appointment_checklists.id'))
    status = Column(String, nullable=False, default='pending')  # pending, completed
    updated_at = Column(DateTime, nullable=False)
    checklist = relationship("AppointmentChecklist")

class AppointmentStatusHistory(Base):
    __tablename__ = 'appointment_status_history'
    id = Column(Integer, primary_key=True, index=True)
    appointment_id = Column(Integer, ForeignKey('appointments.id'))
    status = Column(String, nullable=False)
    changed_at = Column(DateTime, nullable=False)
    appointment = relationship("Appointment")

class EventLog(Base):
    __tablename__ = 'event_log'
    id = Column(Integer, primary_key=True, index=True)
    event_type = Column(String, nullable=False)  # expense, delay, check-in, appointment, chat, task
    event_data = Column(String, nullable=False)  # JSON data for the event
    family_unit_id = Column(Integer, ForeignKey('family_units.id'))
    created_at = Column(DateTime, nullable=False)
    family = relationship("FamilyUnit")

class Report(Base):
    __tablename__ = 'reports'
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False)
    filters = Column(String, nullable=False)  # JSON representation of filters applied
    pdf_url = Column(String, nullable=False)
    hash_sha256 = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False)
    family_unit_id = Column(Integer, ForeignKey('family_units.id'))
    family = relationship("FamilyUnit")

class Notification(Base):
    __tablename__ = 'notifications'
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    content = Column(String, nullable=False)
    type = Column(String, nullable=False) # info, success, warning, error
    read_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False)
    user_id = Column(Integer, ForeignKey('users.id'))
    family_unit_id = Column(Integer, ForeignKey('family_units.id'))
    user = relationship("User")
    family = relationship("FamilyUnit")

class Agreement(Base):
    __tablename__ = 'agreements'
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    content = Column(Text, nullable=False)
    status = Column(String, nullable=False, default='draft') # draft, approved, signed, fulfilled, cancelled
    family_unit_id = Column(Integer, ForeignKey('family_units.id'))
    created_at = Column(DateTime, nullable=False)
    approved_at = Column(DateTime, nullable=True)
    fulfilled_at = Column(DateTime, nullable=True)
    deleted_at = Column(DateTime, nullable=True)
    family = relationship("FamilyUnit")
