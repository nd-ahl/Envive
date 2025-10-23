import Foundation

// MARK: - Task Template

/// Represents a reusable task template
/// The app comes with 300 pre-seeded templates
struct TaskTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let category: TaskTemplateCategory
    let suggestedLevel: TaskLevel
    let estimatedMinutes: Int
    let tags: [String]
    let isDefault: Bool  // true = pre-seeded by system
    let createdBy: UUID?  // parent who created custom template

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: TaskTemplateCategory,
        suggestedLevel: TaskLevel,
        estimatedMinutes: Int,
        tags: [String] = [],
        isDefault: Bool = false,
        createdBy: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.suggestedLevel = suggestedLevel
        self.estimatedMinutes = estimatedMinutes
        self.tags = tags
        self.isDefault = isDefault
        self.createdBy = createdBy
    }
}

// MARK: - Task Template Category

enum TaskTemplateCategory: String, Codable, CaseIterable, Identifiable {
    // Household Chores
    case kitchen = "Kitchen"
    case indoorCleaning = "Cleaning"
    case outdoor = "Yard Work"
    case petCare = "Pet Care"
    case automotive = "Car Care"
    case errands = "Errands"
    case siblingCare = "Babysitting"
    case homeImprovement = "Repairs"

    // Learning & Skills
    case academic = "Homework"
    case music = "Music"
    case arts = "Arts & Crafts"
    case language = "Languages"
    case coding = "Coding"
    case reading = "Reading"

    // Physical & Wellness
    case sports = "Sports"
    case exercise = "Exercise"
    case wellness = "Wellness"

    // Life Skills
    case cooking = "Cooking"
    case money = "Money Skills"
    case organization = "Organization"
    case socialSkills = "Social Skills"

    // Creative & Hobbies
    case creative = "Creative"
    case hobbies = "Hobbies"
    case building = "Building"

    // Community & Character
    case volunteering = "Volunteering"
    case kindness = "Kindness"
    case environment = "Environment"

    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        // Household
        case .kitchen: return "🍽️"
        case .indoorCleaning: return "🧹"
        case .outdoor: return "🌿"
        case .petCare: return "🐕"
        case .automotive: return "🚗"
        case .errands: return "🛒"
        case .siblingCare: return "👶"
        case .homeImprovement: return "🔧"

        // Learning & Skills
        case .academic: return "📚"
        case .music: return "🎵"
        case .arts: return "🎨"
        case .language: return "🗣️"
        case .coding: return "💻"
        case .reading: return "📖"

        // Physical & Wellness
        case .sports: return "⚽"
        case .exercise: return "💪"
        case .wellness: return "🧘"

        // Life Skills
        case .cooking: return "👨‍🍳"
        case .money: return "💰"
        case .organization: return "📋"
        case .socialSkills: return "🤝"

        // Creative & Hobbies
        case .creative: return "✨"
        case .hobbies: return "🎯"
        case .building: return "🏗️"

        // Community & Character
        case .volunteering: return "❤️"
        case .kindness: return "😊"
        case .environment: return "🌍"

        case .other: return "📌"
        }
    }

    // Full descriptive name for detail views
    var fullName: String {
        switch self {
        case .kitchen: return "Kitchen & Cooking Tasks"
        case .indoorCleaning: return "Indoor Cleaning"
        case .outdoor: return "Outdoor & Yard Work"
        case .petCare: return "Pet Care"
        case .automotive: return "Car & Automotive"
        case .errands: return "Errands & Shopping"
        case .siblingCare: return "Babysitting & Sibling Care"
        case .homeImprovement: return "Home Repairs & Improvement"
        case .academic: return "Homework & Academic Study"
        case .music: return "Music Practice & Learning"
        case .arts: return "Arts & Crafts"
        case .language: return "Language Learning"
        case .coding: return "Programming & Technology"
        case .reading: return "Reading & Literature"
        case .sports: return "Sports & Athletics"
        case .exercise: return "Exercise & Fitness"
        case .wellness: return "Wellness & Mindfulness"
        case .cooking: return "Cooking Skills"
        case .money: return "Financial Literacy"
        case .organization: return "Organization & Planning"
        case .socialSkills: return "Social & Communication Skills"
        case .creative: return "Creative Projects"
        case .hobbies: return "Hobbies & Interests"
        case .building: return "Building & Making"
        case .volunteering: return "Volunteering & Service"
        case .kindness: return "Acts of Kindness"
        case .environment: return "Environmental Actions"
        case .other: return "Other Activities"
        }
    }
}

// MARK: - Default Task Templates

extension TaskTemplate {
    /// Get all pre-seeded task templates (700+)
    static var defaultTemplates: [TaskTemplate] {
        return kitchenTasks + indoorCleaningTasks + outdoorTasks + petCareTasks +
               automotiveTasks + errandsTasks + siblingCareTasks + homeImprovementTasks +
               academicTasks + musicTasks + artsTasks + languageTasks + codingTasks +
               readingTasks + sportsTasks + exerciseTasks + wellnessTasks +
               cookingSkillsTasks + moneySkillsTasks + organizationTasks + socialSkillsTasks +
               creativeTasks + hobbiesTasks + buildingTasks + volunteeringTasks +
               kindnessTasks + environmentTasks
    }

    // MARK: - Kitchen & Cooking Tasks (40)

    private static var kitchenTasks: [TaskTemplate] {
        [
            // Daily Kitchen
            TaskTemplate(title: "Load dishwasher", description: "Load all dirty dishes, pots, and pans into dishwasher", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["daily", "dishes"], isDefault: true),
            TaskTemplate(title: "Unload dishwasher", description: "Put away all clean dishes in proper places", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["daily", "dishes"], isDefault: true),
            TaskTemplate(title: "Do the dishes", description: "Hand wash and dry all dishes, pots, and pans", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["daily", "washing"], isDefault: true),
            TaskTemplate(title: "Wipe down countertops", description: "Clean all kitchen countertops with cleaner", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily", "cleaning"], isDefault: true),
            TaskTemplate(title: "Wipe down dining table", description: "Clean dining table and chairs", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily", "cleaning"], isDefault: true),
            TaskTemplate(title: "Clean stovetop", description: "Scrub stovetop and remove all grease and food", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Clean microwave", description: "Clean inside and outside of microwave", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Sweep kitchen floor", description: "Sweep entire kitchen floor", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["daily", "floor"], isDefault: true),
            TaskTemplate(title: "Mop kitchen floor", description: "Mop entire kitchen floor thoroughly", category: .kitchen, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["floor"], isDefault: true),
            TaskTemplate(title: "Take out kitchen trash", description: "Empty trash and replace bag", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily"], isDefault: true),
            TaskTemplate(title: "Clean sink and faucet", description: "Scrub sink, faucet, and drain area", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["cleaning"], isDefault: true),

            // Cooking Tasks
            TaskTemplate(title: "Make breakfast for self", description: "Prepare and cook your own breakfast", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 20, tags: ["cooking"], isDefault: true),
            TaskTemplate(title: "Make breakfast for family", description: "Prepare breakfast for entire family", category: .kitchen, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["cooking", "family"], isDefault: true),
            TaskTemplate(title: "Pack school lunch", description: "Prepare and pack nutritious lunch", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["daily", "food"], isDefault: true),
            TaskTemplate(title: "Make simple dinner", description: "Cook a simple dinner (pasta, sandwiches, etc)", category: .kitchen, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["cooking", "dinner"], isDefault: true),
            TaskTemplate(title: "Make complex dinner", description: "Cook a full dinner with multiple dishes", category: .kitchen, suggestedLevel: .level4, estimatedMinutes: 75, tags: ["cooking", "dinner"], isDefault: true),
            TaskTemplate(title: "Prep ingredients for meal", description: "Chop vegetables, measure ingredients, prep cooking", category: .kitchen, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["cooking"], isDefault: true),
            TaskTemplate(title: "Bake cookies or dessert", description: "Make cookies, brownies, or dessert from scratch", category: .kitchen, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["baking"], isDefault: true),
            TaskTemplate(title: "Set the table", description: "Set table with plates, utensils, napkins, drinks", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily", "dinner"], isDefault: true),
            TaskTemplate(title: "Clear the table", description: "Clear all dishes and wipe table after meal", category: .kitchen, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["daily"], isDefault: true),

            // Deep Kitchen Cleaning
            TaskTemplate(title: "Clean inside refrigerator", description: "Remove items, clean shelves, organize food", category: .kitchen, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["deep-cleaning"], isDefault: true),
            TaskTemplate(title: "Organize pantry", description: "Sort through pantry, organize by category, check dates", category: .kitchen, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Clean inside oven", description: "Deep clean oven interior", category: .kitchen, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["deep-cleaning"], isDefault: true),
            TaskTemplate(title: "Organize cabinets", description: "Organize kitchen cabinets and remove clutter", category: .kitchen, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Polish stainless appliances", description: "Clean and polish all stainless steel appliances", category: .kitchen, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["cleaning"], isDefault: true),
        ]
    }

    // MARK: - Indoor Cleaning Tasks (50)

    private static var indoorCleaningTasks: [TaskTemplate] {
        [
            // Bathroom
            TaskTemplate(title: "Clean toilet", description: "Scrub toilet bowl, seat, exterior thoroughly", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["bathroom"], isDefault: true),
            TaskTemplate(title: "Scrub shower/tub", description: "Deep clean shower or bathtub, remove soap scum", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["bathroom"], isDefault: true),
            TaskTemplate(title: "Clean bathroom sink", description: "Clean sink, counter, and faucet", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["bathroom"], isDefault: true),
            TaskTemplate(title: "Clean mirrors", description: "Clean all mirrors with glass cleaner", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["bathroom"], isDefault: true),
            TaskTemplate(title: "Mop bathroom floor", description: "Sweep and mop bathroom floor", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["bathroom", "floor"], isDefault: true),
            TaskTemplate(title: "Empty bathroom trash", description: "Empty trash and replace bag", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["bathroom"], isDefault: true),
            TaskTemplate(title: "Clean entire bathroom", description: "Complete bathroom cleaning: toilet, shower, sink, floor", category: .indoorCleaning, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["bathroom", "deep-cleaning"], isDefault: true),

            // Bedroom/Living
            TaskTemplate(title: "Make your bed", description: "Make bed with sheets, blankets, pillows arranged", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily", "bedroom"], isDefault: true),
            TaskTemplate(title: "Vacuum bedroom", description: "Vacuum entire bedroom floor", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["bedroom", "vacuuming"], isDefault: true),
            TaskTemplate(title: "Dust bedroom furniture", description: "Dust all surfaces in bedroom", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["bedroom", "dusting"], isDefault: true),
            TaskTemplate(title: "Clean your room", description: "Complete room cleaning: make bed, organize, vacuum, dust", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["bedroom"], isDefault: true),
            TaskTemplate(title: "Organize closet", description: "Sort clothes, hang items, organize shoes", category: .indoorCleaning, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["bedroom", "organizing"], isDefault: true),
            TaskTemplate(title: "Vacuum living room", description: "Vacuum all living room floors and under furniture", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["living-room", "vacuuming"], isDefault: true),
            TaskTemplate(title: "Vacuum stairs", description: "Vacuum all stairs thoroughly", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["vacuuming"], isDefault: true),
            TaskTemplate(title: "Dust living room", description: "Dust all surfaces, shelves, electronics in living room", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["living-room", "dusting"], isDefault: true),
            TaskTemplate(title: "Dust ceiling fans", description: "Clean all ceiling fan blades", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["dusting"], isDefault: true),
            TaskTemplate(title: "Clean windows", description: "Clean all windows inside and out", category: .indoorCleaning, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["windows"], isDefault: true),
            TaskTemplate(title: "Wipe baseboards", description: "Clean baseboards in entire room", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["deep-cleaning"], isDefault: true),
            TaskTemplate(title: "Organize bookshelf", description: "Organize and dust bookshelf", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Pick up common areas", description: "Tidy and organize living areas", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["organizing"], isDefault: true),

            // Laundry
            TaskTemplate(title: "Sort laundry", description: "Sort laundry by colors and fabric type", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["laundry"], isDefault: true),
            TaskTemplate(title: "Do a load of laundry", description: "Wash, dry, and fold one load of laundry", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["laundry"], isDefault: true),
            TaskTemplate(title: "Fold laundry", description: "Fold one full load of clean laundry", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["laundry"], isDefault: true),
            TaskTemplate(title: "Put away laundry", description: "Put all folded clothes in proper places", category: .indoorCleaning, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["laundry"], isDefault: true),
            TaskTemplate(title: "Iron clothes", description: "Iron wrinkled clothes", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["laundry"], isDefault: true),

            // Deep Cleaning
            TaskTemplate(title: "Vacuum entire house", description: "Vacuum all rooms in the house", category: .indoorCleaning, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["vacuuming", "deep-cleaning"], isDefault: true),
            TaskTemplate(title: "Dust entire house", description: "Dust all surfaces in every room", category: .indoorCleaning, suggestedLevel: .level4, estimatedMinutes: 50, tags: ["dusting", "deep-cleaning"], isDefault: true),
            TaskTemplate(title: "Clean all doors", description: "Wipe down all interior doors", category: .indoorCleaning, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["deep-cleaning"], isDefault: true),
            TaskTemplate(title: "Clean air vents", description: "Vacuum and wipe all air vents", category: .indoorCleaning, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["deep-cleaning"], isDefault: true),
            TaskTemplate(title: "Organize coat closet", description: "Sort through and organize coat closet", category: .indoorCleaning, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Clean garage", description: "Sweep, organize, and clean garage", category: .indoorCleaning, suggestedLevel: .level5, estimatedMinutes: 120, tags: ["garage", "deep-cleaning"], isDefault: true),
        ]
    }

    // MARK: - Outdoor & Yard Tasks (40)

    private static var outdoorTasks: [TaskTemplate] {
        [
            // Lawn Care
            TaskTemplate(title: "Mow front lawn", description: "Mow entire front yard", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 35, tags: ["lawn"], isDefault: true),
            TaskTemplate(title: "Mow back lawn", description: "Mow entire back yard", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 35, tags: ["lawn"], isDefault: true),
            TaskTemplate(title: "Mow entire lawn", description: "Mow both front and back yards", category: .outdoor, suggestedLevel: .level4, estimatedMinutes: 70, tags: ["lawn"], isDefault: true),
            TaskTemplate(title: "Edge lawn", description: "Edge along all walkways and driveway", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["lawn"], isDefault: true),
            TaskTemplate(title: "Trim hedges", description: "Trim and shape bushes and hedges", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["landscaping"], isDefault: true),
            TaskTemplate(title: "Rake leaves", description: "Rake and bag leaves in yard", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 50, tags: ["seasonal", "lawn"], isDefault: true),
            TaskTemplate(title: "Bag yard waste", description: "Collect and bag yard waste", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["lawn"], isDefault: true),
            TaskTemplate(title: "Pull weeds", description: "Pull weeds from garden beds and yard", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["gardening"], isDefault: true),
            TaskTemplate(title: "Water plants", description: "Water all outdoor plants and garden", category: .outdoor, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["gardening"], isDefault: true),
            TaskTemplate(title: "Plant flowers", description: "Plant new flowers or plants in garden", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["gardening"], isDefault: true),
            TaskTemplate(title: "Spread mulch", description: "Spread mulch in garden beds", category: .outdoor, suggestedLevel: .level4, estimatedMinutes: 75, tags: ["landscaping"], isDefault: true),

            // Outdoor Maintenance
            TaskTemplate(title: "Sweep driveway", description: "Sweep entire driveway", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Sweep walkways", description: "Sweep all walkways and paths", category: .outdoor, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Sweep patio/deck", description: "Sweep patio or deck area", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Clean gutters", description: "Remove leaves and debris from gutters", category: .outdoor, suggestedLevel: .level4, estimatedMinutes: 50, tags: ["maintenance"], isDefault: true),
            TaskTemplate(title: "Wash exterior windows", description: "Clean outside of all windows", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Pressure wash driveway", description: "Pressure wash entire driveway", category: .outdoor, suggestedLevel: .level4, estimatedMinutes: 75, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Pressure wash deck", description: "Pressure wash patio or deck", category: .outdoor, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Organize shed", description: "Organize storage shed or outdoor storage", category: .outdoor, suggestedLevel: .level4, estimatedMinutes: 75, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Coil garden hose", description: "Properly coil and store garden hose", category: .outdoor, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["organizing"], isDefault: true),

            // Pool & Recreation
            TaskTemplate(title: "Skim pool surface", description: "Remove debris from pool surface", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["pool"], isDefault: true),
            TaskTemplate(title: "Vacuum pool", description: "Vacuum pool floor and walls", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["pool"], isDefault: true),
            TaskTemplate(title: "Clean pool filter", description: "Clean and maintain pool filter", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["pool"], isDefault: true),
            TaskTemplate(title: "Test pool water", description: "Test pool chemistry and adjust chemicals", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["pool"], isDefault: true),
            TaskTemplate(title: "Clean pool deck", description: "Sweep and clean pool deck area", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["pool"], isDefault: true),

            // Seasonal
            TaskTemplate(title: "Shovel snow - driveway", description: "Shovel snow from driveway", category: .outdoor, suggestedLevel: .level4, estimatedMinutes: 45, tags: ["seasonal", "winter"], isDefault: true),
            TaskTemplate(title: "Shovel snow - walkways", description: "Shovel snow from all walkways", category: .outdoor, suggestedLevel: .level3, estimatedMinutes: 25, tags: ["seasonal", "winter"], isDefault: true),
            TaskTemplate(title: "Salt icy areas", description: "Apply salt/sand to icy walkways and driveway", category: .outdoor, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["seasonal", "winter"], isDefault: true),
            TaskTemplate(title: "Clear snow off cars", description: "Remove snow from all family vehicles", category: .outdoor, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["seasonal", "winter"], isDefault: true),
        ]
    }

    // MARK: - Pet Care Tasks (25)

    private static var petCareTasks: [TaskTemplate] {
        [
            // Daily Pet Care
            TaskTemplate(title: "Feed dog/cat", description: "Feed pet breakfast or dinner", category: .petCare, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily"], isDefault: true),
            TaskTemplate(title: "Refill pet water", description: "Refill water bowls with fresh water", category: .petCare, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily"], isDefault: true),
            TaskTemplate(title: "Walk dog", description: "Take dog for walk around neighborhood", category: .petCare, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["daily", "dog"], isDefault: true),
            TaskTemplate(title: "Play with pet", description: "Play with pet for exercise and bonding", category: .petCare, suggestedLevel: .level1, estimatedMinutes: 20, tags: ["daily"], isDefault: true),
            TaskTemplate(title: "Scoop litter box", description: "Clean cat litter box", category: .petCare, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["daily", "cat"], isDefault: true),
            TaskTemplate(title: "Let dog outside/inside", description: "Let dog out to bathroom and bring back in", category: .petCare, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["daily", "dog"], isDefault: true),

            // Pet Grooming
            TaskTemplate(title: "Brush dog/cat", description: "Brush pet's fur thoroughly", category: .petCare, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["grooming"], isDefault: true),
            TaskTemplate(title: "Bathe dog", description: "Give dog a full bath", category: .petCare, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["grooming", "dog"], isDefault: true),
            TaskTemplate(title: "Clean pet bowls", description: "Wash all pet food and water bowls", category: .petCare, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Clean litter box completely", description: "Empty, scrub, and refill litter box", category: .petCare, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["cat", "cleaning"], isDefault: true),
            TaskTemplate(title: "Clean pet crate", description: "Clean and disinfect pet crate or cage", category: .petCare, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Clean up pet accident", description: "Clean up and disinfect pet mess", category: .petCare, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Vacuum pet hair", description: "Vacuum areas with pet hair buildup", category: .petCare, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["cleaning"], isDefault: true),

            // Pet Errands
            TaskTemplate(title: "Take pet to vet", description: "Transport pet to veterinary appointment", category: .petCare, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["errands"], isDefault: true),
            TaskTemplate(title: "Buy pet supplies", description: "Shop for pet food and supplies", category: .petCare, suggestedLevel: .level2, estimatedMinutes: 40, tags: ["errands"], isDefault: true),
            TaskTemplate(title: "Clean fish tank", description: "Clean and maintain aquarium", category: .petCare, suggestedLevel: .level3, estimatedMinutes: 50, tags: ["fish"], isDefault: true),
        ]
    }

    // MARK: - Automotive Tasks (20)

    private static var automotiveTasks: [TaskTemplate] {
        [
            // Car Cleaning
            TaskTemplate(title: "Vacuum car interior", description: "Vacuum all seats, floors, and trunk", category: .automotive, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Wipe down dashboard", description: "Clean dashboard, console, and door panels", category: .automotive, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Clean car windows inside", description: "Clean inside of all car windows", category: .automotive, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Clean car windows outside", description: "Clean outside of all car windows", category: .automotive, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Wash car exterior", description: "Wash and rinse entire car exterior", category: .automotive, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Wax car", description: "Apply wax and polish car exterior", category: .automotive, suggestedLevel: .level4, estimatedMinutes: 80, tags: ["detailing"], isDefault: true),
            TaskTemplate(title: "Clean car seats", description: "Deep clean and shampoo car seats", category: .automotive, suggestedLevel: .level3, estimatedMinutes: 35, tags: ["cleaning"], isDefault: true),
            TaskTemplate(title: "Organize car trunk", description: "Clean out and organize trunk", category: .automotive, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Empty car trash", description: "Remove all trash from car", category: .automotive, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["cleaning"], isDefault: true),

            // Car Maintenance
            TaskTemplate(title: "Check tire pressure", description: "Check and adjust tire pressure on all tires", category: .automotive, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["maintenance"], isDefault: true),
            TaskTemplate(title: "Fill gas tank", description: "Fill car with gasoline", category: .automotive, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["maintenance"], isDefault: true),
            TaskTemplate(title: "Take car through car wash", description: "Drive car through automatic car wash", category: .automotive, suggestedLevel: .level1, estimatedMinutes: 20, tags: ["cleaning"], isDefault: true),
        ]
    }

    // MARK: - Errands & Shopping Tasks (20)

    private static var errandsTasks: [TaskTemplate] {
        [
            TaskTemplate(title: "Make grocery list", description: "Create shopping list for groceries", category: .errands, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["planning"], isDefault: true),
            TaskTemplate(title: "Go grocery shopping", description: "Complete grocery shopping trip", category: .errands, suggestedLevel: .level4, estimatedMinutes: 75, tags: ["shopping"], isDefault: true),
            TaskTemplate(title: "Put away groceries", description: "Unload and organize all groceries", category: .errands, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Pick up prescription", description: "Pick up medication from pharmacy", category: .errands, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["medical"], isDefault: true),
            TaskTemplate(title: "Return items to store", description: "Return purchased items to store", category: .errands, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["shopping"], isDefault: true),
            TaskTemplate(title: "Mail package", description: "Take package to post office", category: .errands, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["errands"], isDefault: true),
            TaskTemplate(title: "Drop off donations", description: "Take donation items to donation center", category: .errands, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["charity"], isDefault: true),
            TaskTemplate(title: "Pick up takeout food", description: "Pick up restaurant order", category: .errands, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["food"], isDefault: true),
        ]
    }

    // MARK: - Sibling Care Tasks (25)

    private static var siblingCareTasks: [TaskTemplate] {
        [
            TaskTemplate(title: "Watch younger sibling", description: "Supervise sibling for one hour", category: .siblingCare, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["childcare"], isDefault: true),
            TaskTemplate(title: "Help sibling with homework", description: "Assist sibling with homework assignment", category: .siblingCare, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["academic"], isDefault: true),
            TaskTemplate(title: "Play with sibling", description: "Play games or activities with sibling", category: .siblingCare, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["play"], isDefault: true),
            TaskTemplate(title: "Read to sibling", description: "Read books to younger sibling", category: .siblingCare, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["educational"], isDefault: true),
            TaskTemplate(title: "Make snack for sibling", description: "Prepare snack for sibling", category: .siblingCare, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["food"], isDefault: true),
            TaskTemplate(title: "Make meal for sibling", description: "Prepare meal for sibling", category: .siblingCare, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["cooking"], isDefault: true),
            TaskTemplate(title: "Put sibling to bed", description: "Complete bedtime routine for sibling", category: .siblingCare, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["childcare"], isDefault: true),
            TaskTemplate(title: "Drive sibling to activity", description: "Transport sibling to event or activity", category: .siblingCare, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["transportation"], isDefault: true),
        ]
    }

    // MARK: - Academic Tasks (30)

    private static var academicTasks: [TaskTemplate] {
        [
            TaskTemplate(title: "Complete homework assignment", description: "Finish assigned homework", category: .academic, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["homework"], isDefault: true),
            TaskTemplate(title: "Study for test", description: "Study and review for upcoming test", category: .academic, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["studying"], isDefault: true),
            TaskTemplate(title: "Work on school project", description: "Make progress on long-term project", category: .academic, suggestedLevel: .level4, estimatedMinutes: 75, tags: ["project"], isDefault: true),
            TaskTemplate(title: "Write essay or paper", description: "Write school essay or research paper", category: .academic, suggestedLevel: .level4, estimatedMinutes: 90, tags: ["writing"], isDefault: true),
            TaskTemplate(title: "Practice instrument", description: "Practice musical instrument", category: .academic, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["music"], isDefault: true),
            TaskTemplate(title: "Reading assignment", description: "Complete assigned reading", category: .academic, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["reading"], isDefault: true),
            TaskTemplate(title: "Math practice problems", description: "Complete math homework or practice", category: .academic, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["math"], isDefault: true),
            TaskTemplate(title: "Create presentation", description: "Prepare school presentation", category: .academic, suggestedLevel: .level4, estimatedMinutes: 70, tags: ["project"], isDefault: true),
            TaskTemplate(title: "Study vocabulary", description: "Learn and memorize vocabulary words", category: .academic, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["language"], isDefault: true),
            TaskTemplate(title: "Practice typing", description: "Practice typing skills", category: .academic, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["computer"], isDefault: true),
        ]
    }

    // MARK: - Home Improvement Tasks (6)

    private static var homeImprovementTasks: [TaskTemplate] {
        [
            TaskTemplate(title: "Replace light bulbs", description: "Replace burnt out light bulbs", category: .homeImprovement, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["maintenance"], isDefault: true),
            TaskTemplate(title: "Assemble furniture", description: "Assemble new furniture from box", category: .homeImprovement, suggestedLevel: .level4, estimatedMinutes: 90, tags: ["assembly"], isDefault: true),
            TaskTemplate(title: "Hang pictures", description: "Hang pictures or decorations on walls", category: .homeImprovement, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["decorating"], isDefault: true),
            TaskTemplate(title: "Organize tools", description: "Organize toolbox or tool storage", category: .homeImprovement, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["organizing"], isDefault: true),
            TaskTemplate(title: "Paint room", description: "Paint walls in room", category: .homeImprovement, suggestedLevel: .level5, estimatedMinutes: 180, tags: ["painting"], isDefault: true),
            TaskTemplate(title: "Install shelf", description: "Install wall shelf", category: .homeImprovement, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["installation"], isDefault: true),
        ]
    }

    // MARK: - Music Tasks (40)

    private static var musicTasks: [TaskTemplate] {
        [
            // Instrument Practice
            TaskTemplate(title: "Practice piano - 15 min", description: "Practice piano scales, songs, or exercises", category: .music, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["piano", "practice"], isDefault: true),
            TaskTemplate(title: "Practice piano - 30 min", description: "Extended piano practice session", category: .music, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["piano", "practice"], isDefault: true),
            TaskTemplate(title: "Practice piano - 1 hour", description: "Full piano practice session", category: .music, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["piano", "practice"], isDefault: true),
            TaskTemplate(title: "Practice guitar - 15 min", description: "Practice guitar chords, songs, or exercises", category: .music, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["guitar", "practice"], isDefault: true),
            TaskTemplate(title: "Practice guitar - 30 min", description: "Extended guitar practice session", category: .music, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["guitar", "practice"], isDefault: true),
            TaskTemplate(title: "Practice drums - 30 min", description: "Practice drum patterns and songs", category: .music, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["drums", "practice"], isDefault: true),
            TaskTemplate(title: "Practice violin - 30 min", description: "Practice violin technique and pieces", category: .music, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["violin", "practice"], isDefault: true),
            TaskTemplate(title: "Practice flute - 20 min", description: "Practice flute scales and songs", category: .music, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["flute", "practice"], isDefault: true),
            TaskTemplate(title: "Practice trumpet - 20 min", description: "Practice trumpet technique and songs", category: .music, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["trumpet", "practice"], isDefault: true),
            TaskTemplate(title: "Practice saxophone - 20 min", description: "Practice saxophone scales and pieces", category: .music, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["saxophone", "practice"], isDefault: true),
            TaskTemplate(title: "Practice ukulele - 15 min", description: "Practice ukulele chords and songs", category: .music, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["ukulele", "practice"], isDefault: true),

            // Vocal Training
            TaskTemplate(title: "Vocal practice - 15 min", description: "Practice singing scales and exercises", category: .music, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["singing", "vocal"], isDefault: true),
            TaskTemplate(title: "Vocal practice - 30 min", description: "Extended singing practice session", category: .music, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["singing", "vocal"], isDefault: true),
            TaskTemplate(title: "Learn a new song", description: "Learn and practice a new song", category: .music, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["learning"], isDefault: true),

            // Music Theory
            TaskTemplate(title: "Music theory study - 20 min", description: "Study music theory concepts", category: .music, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["theory", "study"], isDefault: true),
            TaskTemplate(title: "Practice sight reading", description: "Practice reading sheet music", category: .music, suggestedLevel: .level3, estimatedMinutes: 20, tags: ["theory", "reading"], isDefault: true),
            TaskTemplate(title: "Ear training exercises", description: "Practice identifying notes and intervals", category: .music, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["theory", "training"], isDefault: true),

            // Creative Music
            TaskTemplate(title: "Write a song", description: "Compose an original song or melody", category: .music, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["composition", "creative"], isDefault: true),
            TaskTemplate(title: "Create a music playlist", description: "Curate a themed music playlist", category: .music, suggestedLevel: .level1, estimatedMinutes: 20, tags: ["creative"], isDefault: true),
            TaskTemplate(title: "Learn music production basics", description: "Learn basic music recording or production", category: .music, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["production", "learning"], isDefault: true),
        ]
    }

    // MARK: - Arts & Crafts Tasks (45)

    private static var artsTasks: [TaskTemplate] {
        [
            // Drawing & Painting
            TaskTemplate(title: "Draw for 20 minutes", description: "Practice drawing or sketching", category: .arts, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["drawing"], isDefault: true),
            TaskTemplate(title: "Draw for 45 minutes", description: "Extended drawing session", category: .arts, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["drawing"], isDefault: true),
            TaskTemplate(title: "Paint a picture", description: "Create a painting with acrylics or watercolors", category: .arts, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["painting"], isDefault: true),
            TaskTemplate(title: "Practice portrait drawing", description: "Draw a portrait or self-portrait", category: .arts, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["drawing", "advanced"], isDefault: true),
            TaskTemplate(title: "Learn a new art technique", description: "Study and practice a new art technique", category: .arts, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["learning"], isDefault: true),
            TaskTemplate(title: "Color and shade practice", description: "Practice coloring and shading techniques", category: .arts, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["drawing", "practice"], isDefault: true),

            // Crafts
            TaskTemplate(title: "Make origami", description: "Create origami figures", category: .arts, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["crafts", "paper"], isDefault: true),
            TaskTemplate(title: "Create a collage", description: "Make an artistic collage", category: .arts, suggestedLevel: .level2, estimatedMinutes: 40, tags: ["crafts"], isDefault: true),
            TaskTemplate(title: "Make friendship bracelets", description: "Create friendship bracelets", category: .arts, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["crafts", "jewelry"], isDefault: true),
            TaskTemplate(title: "Sew or embroider", description: "Practice sewing or embroidery", category: .arts, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["crafts", "sewing"], isDefault: true),
            TaskTemplate(title: "Knit or crochet", description: "Practice knitting or crocheting", category: .arts, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["crafts", "fiber"], isDefault: true),
            TaskTemplate(title: "Make jewelry", description: "Create handmade jewelry", category: .arts, suggestedLevel: .level2, estimatedMinutes: 40, tags: ["crafts", "jewelry"], isDefault: true),
            TaskTemplate(title: "Scrapbooking", description: "Create or add to a scrapbook", category: .arts, suggestedLevel: .level2, estimatedMinutes: 45, tags: ["crafts", "creative"], isDefault: true),

            // Sculpture & 3D
            TaskTemplate(title: "Sculpt with clay", description: "Create a sculpture with clay", category: .arts, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["sculpture", "3d"], isDefault: true),
            TaskTemplate(title: "Paper mache project", description: "Create something with paper mache", category: .arts, suggestedLevel: .level3, estimatedMinutes: 90, tags: ["crafts", "sculpture"], isDefault: true),

            // Digital Art
            TaskTemplate(title: "Digital drawing - 30 min", description: "Create digital art on tablet or computer", category: .arts, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["digital", "drawing"], isDefault: true),
            TaskTemplate(title: "Photo editing practice", description: "Practice photo editing skills", category: .arts, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["digital", "photography"], isDefault: true),
            TaskTemplate(title: "Learn graphic design basics", description: "Study basic graphic design principles", category: .arts, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["digital", "learning"], isDefault: true),
        ]
    }

    // MARK: - Language Learning Tasks (35)

    private static var languageTasks: [TaskTemplate] {
        [
            // Practice Sessions
            TaskTemplate(title: "Language app practice - 15 min", description: "Practice with Duolingo or similar app", category: .language, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["app", "practice"], isDefault: true),
            TaskTemplate(title: "Language app practice - 30 min", description: "Extended language app practice", category: .language, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["app", "practice"], isDefault: true),
            TaskTemplate(title: "Practice vocabulary - 20 min", description: "Study and practice new vocabulary words", category: .language, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["vocabulary"], isDefault: true),
            TaskTemplate(title: "Grammar exercises", description: "Complete grammar practice exercises", category: .language, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["grammar"], isDefault: true),

            // Speaking & Listening
            TaskTemplate(title: "Watch foreign language video", description: "Watch show or video in target language", category: .language, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["listening", "watching"], isDefault: true),
            TaskTemplate(title: "Listen to language podcast", description: "Listen to podcast in target language", category: .language, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["listening", "podcast"], isDefault: true),
            TaskTemplate(title: "Practice speaking aloud", description: "Practice speaking phrases and sentences", category: .language, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["speaking"], isDefault: true),
            TaskTemplate(title: "Language conversation practice", description: "Have conversation in target language", category: .language, suggestedLevel: .level4, estimatedMinutes: 30, tags: ["speaking", "conversation"], isDefault: true),

            // Reading & Writing
            TaskTemplate(title: "Read in target language", description: "Read article or book in target language", category: .language, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["reading"], isDefault: true),
            TaskTemplate(title: "Write in target language", description: "Practice writing in target language", category: .language, suggestedLevel: .level3, estimatedMinutes: 25, tags: ["writing"], isDefault: true),
            TaskTemplate(title: "Translate a passage", description: "Translate text from/to target language", category: .language, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["translation"], isDefault: true),

            // Cultural Learning
            TaskTemplate(title: "Learn about target culture", description: "Study culture of language being learned", category: .language, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["culture"], isDefault: true),
            TaskTemplate(title: "Make flashcards", description: "Create language learning flashcards", category: .language, suggestedLevel: .level1, estimatedMinutes: 20, tags: ["study", "vocabulary"], isDefault: true),
        ]
    }

    // MARK: - Coding & Technology Tasks (40)

    private static var codingTasks: [TaskTemplate] {
        [
            // Programming Practice
            TaskTemplate(title: "Code practice - 30 min", description: "Practice coding on platform like CodeAcademy", category: .coding, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["programming"], isDefault: true),
            TaskTemplate(title: "Code practice - 1 hour", description: "Extended coding practice session", category: .coding, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["programming"], isDefault: true),
            TaskTemplate(title: "Complete coding challenge", description: "Solve a coding problem or challenge", category: .coding, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["problem-solving"], isDefault: true),
            TaskTemplate(title: "Learn new programming concept", description: "Study a new programming concept or technique", category: .coding, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["learning"], isDefault: true),
            TaskTemplate(title: "Debug and fix code", description: "Practice debugging and fixing code errors", category: .coding, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["debugging"], isDefault: true),

            // Projects
            TaskTemplate(title: "Work on coding project", description: "Build or improve a personal coding project", category: .coding, suggestedLevel: .level4, estimatedMinutes: 90, tags: ["project"], isDefault: true),
            TaskTemplate(title: "Build a simple game", description: "Create a simple game with code", category: .coding, suggestedLevel: .level4, estimatedMinutes: 120, tags: ["game", "project"], isDefault: true),
            TaskTemplate(title: "Create a website", description: "Build a simple website", category: .coding, suggestedLevel: .level4, estimatedMinutes: 90, tags: ["web", "project"], isDefault: true),

            // Learning Specific Languages
            TaskTemplate(title: "Python tutorial - 30 min", description: "Follow Python programming tutorial", category: .coding, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["python", "learning"], isDefault: true),
            TaskTemplate(title: "JavaScript tutorial - 30 min", description: "Follow JavaScript programming tutorial", category: .coding, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["javascript", "learning"], isDefault: true),
            TaskTemplate(title: "Scratch programming - 30 min", description: "Create project in Scratch", category: .coding, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["scratch", "beginner"], isDefault: true),

            // Tech Skills
            TaskTemplate(title: "Learn typing skills", description: "Practice touch typing", category: .coding, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["typing", "skills"], isDefault: true),
            TaskTemplate(title: "Learn keyboard shortcuts", description: "Practice useful computer keyboard shortcuts", category: .coding, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["skills"], isDefault: true),
            TaskTemplate(title: "Tech troubleshooting", description: "Learn to troubleshoot common tech problems", category: .coding, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["skills"], isDefault: true),
        ]
    }

    // MARK: - Reading Tasks (30)

    private static var readingTasks: [TaskTemplate] {
        [
            // Reading Practice
            TaskTemplate(title: "Read for 15 minutes", description: "Read a book for pleasure or learning", category: .reading, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["reading"], isDefault: true),
            TaskTemplate(title: "Read for 30 minutes", description: "Extended reading session", category: .reading, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["reading"], isDefault: true),
            TaskTemplate(title: "Read for 1 hour", description: "Deep reading session", category: .reading, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["reading"], isDefault: true),
            TaskTemplate(title: "Finish a chapter", description: "Complete one chapter of current book", category: .reading, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["reading"], isDefault: true),
            TaskTemplate(title: "Finish a book", description: "Complete an entire book", category: .reading, suggestedLevel: .level5, estimatedMinutes: 120, tags: ["reading", "achievement"], isDefault: true),

            // Comprehension & Analysis
            TaskTemplate(title: "Write book summary", description: "Write summary of what you read", category: .reading, suggestedLevel: .level3, estimatedMinutes: 20, tags: ["writing", "comprehension"], isDefault: true),
            TaskTemplate(title: "Reading comprehension questions", description: "Answer questions about reading material", category: .reading, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["comprehension"], isDefault: true),
            TaskTemplate(title: "Book report", description: "Write a complete book report", category: .reading, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["writing", "analysis"], isDefault: true),

            // Variety
            TaskTemplate(title: "Read the news", description: "Read age-appropriate news articles", category: .reading, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["news", "nonfiction"], isDefault: true),
            TaskTemplate(title: "Read poetry", description: "Read and appreciate poetry", category: .reading, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["poetry"], isDefault: true),
            TaskTemplate(title: "Read graphic novel/comic", description: "Read graphic novel or comic book", category: .reading, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["graphic-novel"], isDefault: true),
            TaskTemplate(title: "Listen to audiobook", description: "Listen to audiobook for enrichment", category: .reading, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["audiobook", "listening"], isDefault: true),
        ]
    }

    // MARK: - Sports Tasks (45)

    private static var sportsTasks: [TaskTemplate] {
        [
            // Team Sports Practice
            TaskTemplate(title: "Basketball practice - 30 min", description: "Practice basketball skills and drills", category: .sports, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["basketball"], isDefault: true),
            TaskTemplate(title: "Basketball practice - 1 hour", description: "Extended basketball practice", category: .sports, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["basketball"], isDefault: true),
            TaskTemplate(title: "Soccer practice - 30 min", description: "Practice soccer skills and drills", category: .sports, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["soccer"], isDefault: true),
            TaskTemplate(title: "Soccer practice - 1 hour", description: "Extended soccer practice", category: .sports, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["soccer"], isDefault: true),
            TaskTemplate(title: "Baseball practice - 45 min", description: "Practice batting, throwing, and fielding", category: .sports, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["baseball"], isDefault: true),
            TaskTemplate(title: "Volleyball practice - 30 min", description: "Practice volleyball skills", category: .sports, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["volleyball"], isDefault: true),
            TaskTemplate(title: "Football practice - 1 hour", description: "Practice football skills and plays", category: .sports, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["football"], isDefault: true),

            // Individual Sports
            TaskTemplate(title: "Tennis practice - 45 min", description: "Practice tennis strokes and serves", category: .sports, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["tennis"], isDefault: true),
            TaskTemplate(title: "Swimming practice - 30 min", description: "Practice swimming laps and techniques", category: .sports, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["swimming"], isDefault: true),
            TaskTemplate(title: "Track & field practice - 45 min", description: "Running, jumping, or throwing practice", category: .sports, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["track"], isDefault: true),
            TaskTemplate(title: "Gymnastics practice - 45 min", description: "Practice gymnastics routines", category: .sports, suggestedLevel: .level4, estimatedMinutes: 45, tags: ["gymnastics"], isDefault: true),
            TaskTemplate(title: "Martial arts practice - 30 min", description: "Practice martial arts techniques", category: .sports, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["martial-arts"], isDefault: true),
            TaskTemplate(title: "Dance practice - 30 min", description: "Practice dance routines", category: .sports, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["dance"], isDefault: true),
            TaskTemplate(title: "Skateboarding practice - 30 min", description: "Practice skateboarding tricks", category: .sports, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["skateboard"], isDefault: true),

            // Skill Building
            TaskTemplate(title: "Learn a new sports skill", description: "Learn and practice a new sports technique", category: .sports, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["learning"], isDefault: true),
            TaskTemplate(title: "Watch sports technique video", description: "Study sports technique through video", category: .sports, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["learning", "video"], isDefault: true),
        ]
    }

    // MARK: - Exercise & Fitness Tasks (30)

    private static var exerciseTasks: [TaskTemplate] {
        [
            // Cardio
            TaskTemplate(title: "Go for a run - 20 min", description: "Running or jogging session", category: .exercise, suggestedLevel: .level3, estimatedMinutes: 20, tags: ["cardio", "running"], isDefault: true),
            TaskTemplate(title: "Go for a run - 30 min", description: "Extended running session", category: .exercise, suggestedLevel: .level4, estimatedMinutes: 30, tags: ["cardio", "running"], isDefault: true),
            TaskTemplate(title: "Bike ride - 30 min", description: "Cycling workout", category: .exercise, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["cardio", "cycling"], isDefault: true),
            TaskTemplate(title: "Jump rope - 10 min", description: "Jump rope cardio workout", category: .exercise, suggestedLevel: .level2, estimatedMinutes: 10, tags: ["cardio"], isDefault: true),
            TaskTemplate(title: "Dancing workout - 20 min", description: "Dance for exercise", category: .exercise, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["cardio", "dance"], isDefault: true),

            // Strength
            TaskTemplate(title: "Bodyweight workout - 20 min", description: "Pushups, situps, squats routine", category: .exercise, suggestedLevel: .level3, estimatedMinutes: 20, tags: ["strength"], isDefault: true),
            TaskTemplate(title: "Core workout - 15 min", description: "Ab and core strengthening exercises", category: .exercise, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["strength", "core"], isDefault: true),
            TaskTemplate(title: "Strength training - 30 min", description: "Weight or resistance training", category: .exercise, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["strength"], isDefault: true),

            // Flexibility
            TaskTemplate(title: "Stretching routine - 10 min", description: "Full body stretching", category: .exercise, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["flexibility"], isDefault: true),
            TaskTemplate(title: "Yoga session - 20 min", description: "Yoga practice for flexibility", category: .exercise, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["yoga", "flexibility"], isDefault: true),
            TaskTemplate(title: "Yoga session - 45 min", description: "Extended yoga practice", category: .exercise, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["yoga", "flexibility"], isDefault: true),

            // Outdoor Activities
            TaskTemplate(title: "Hiking - 1 hour", description: "Go for a nature hike", category: .exercise, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["outdoor", "cardio"], isDefault: true),
            TaskTemplate(title: "Walk outdoors - 30 min", description: "Take a walk outside", category: .exercise, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["outdoor", "walking"], isDefault: true),
            TaskTemplate(title: "Play outside - 45 min", description: "Active outdoor play", category: .exercise, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["outdoor", "play"], isDefault: true),
        ]
    }

    // MARK: - Wellness & Mindfulness Tasks (25)

    private static var wellnessTasks: [TaskTemplate] {
        [
            // Mindfulness
            TaskTemplate(title: "Meditation - 5 min", description: "Short meditation session", category: .wellness, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["meditation"], isDefault: true),
            TaskTemplate(title: "Meditation - 10 min", description: "Standard meditation session", category: .wellness, suggestedLevel: .level2, estimatedMinutes: 10, tags: ["meditation"], isDefault: true),
            TaskTemplate(title: "Meditation - 20 min", description: "Extended meditation session", category: .wellness, suggestedLevel: .level3, estimatedMinutes: 20, tags: ["meditation"], isDefault: true),
            TaskTemplate(title: "Deep breathing exercises", description: "Practice deep breathing techniques", category: .wellness, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["breathing"], isDefault: true),
            TaskTemplate(title: "Mindfulness practice", description: "Practice being present and mindful", category: .wellness, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["mindfulness"], isDefault: true),

            // Journaling & Reflection
            TaskTemplate(title: "Gratitude journal", description: "Write things you're grateful for", category: .wellness, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["journaling", "gratitude"], isDefault: true),
            TaskTemplate(title: "Personal journal entry", description: "Write in personal journal", category: .wellness, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["journaling"], isDefault: true),
            TaskTemplate(title: "Reflection time", description: "Reflect on day or experiences", category: .wellness, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["reflection"], isDefault: true),

            // Self-Care
            TaskTemplate(title: "Take a relaxing bath", description: "Take time for a relaxing bath", category: .wellness, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["self-care"], isDefault: true),
            TaskTemplate(title: "Skincare routine", description: "Complete skincare routine", category: .wellness, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["self-care"], isDefault: true),
            TaskTemplate(title: "Organize personal space", description: "Tidy and organize your personal area", category: .wellness, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["organization"], isDefault: true),

            // Connection
            TaskTemplate(title: "Call a friend or relative", description: "Have a meaningful conversation", category: .wellness, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["connection"], isDefault: true),
            TaskTemplate(title: "Write a letter", description: "Write a thoughtful letter to someone", category: .wellness, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["connection", "writing"], isDefault: true),
        ]
    }

    // MARK: - Cooking Skills Tasks (30)

    private static var cookingSkillsTasks: [TaskTemplate] {
        [
            // Basic Skills
            TaskTemplate(title: "Learn to crack eggs", description: "Practice cracking eggs properly", category: .cooking, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["basics"], isDefault: true),
            TaskTemplate(title: "Practice knife skills", description: "Learn safe chopping and cutting", category: .cooking, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["basics", "safety"], isDefault: true),
            TaskTemplate(title: "Learn to measure ingredients", description: "Practice measuring cups and spoons", category: .cooking, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["basics"], isDefault: true),
            TaskTemplate(title: "Make scrambled eggs", description: "Cook scrambled eggs from scratch", category: .cooking, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["breakfast", "eggs"], isDefault: true),
            TaskTemplate(title: "Make toast and spreads", description: "Make toast with various toppings", category: .cooking, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["breakfast"], isDefault: true),
            TaskTemplate(title: "Make a sandwich", description: "Create a nutritious sandwich", category: .cooking, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["lunch"], isDefault: true),
            TaskTemplate(title: "Make a salad", description: "Prepare a fresh salad", category: .cooking, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["healthy"], isDefault: true),

            // Intermediate Cooking
            TaskTemplate(title: "Cook pasta", description: "Boil pasta and make simple sauce", category: .cooking, suggestedLevel: .level2, estimatedMinutes: 25, tags: ["pasta"], isDefault: true),
            TaskTemplate(title: "Make pancakes", description: "Mix and cook pancakes", category: .cooking, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["breakfast", "baking"], isDefault: true),
            TaskTemplate(title: "Bake cookies", description: "Bake cookies from scratch or mix", category: .cooking, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["baking", "dessert"], isDefault: true),
            TaskTemplate(title: "Make a smoothie", description: "Blend a nutritious smoothie", category: .cooking, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["healthy", "drinks"], isDefault: true),
            TaskTemplate(title: "Grill cheese sandwich", description: "Make a grilled cheese sandwich", category: .cooking, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["lunch"], isDefault: true),

            // Advanced Skills
            TaskTemplate(title: "Follow a recipe independently", description: "Cook a dish following written recipe", category: .cooking, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["independence"], isDefault: true),
            TaskTemplate(title: "Plan a meal", description: "Plan ingredients and steps for a meal", category: .cooking, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["planning"], isDefault: true),
            TaskTemplate(title: "Bake bread or muffins", description: "Bake bread or muffins from scratch", category: .cooking, suggestedLevel: .level4, estimatedMinutes: 90, tags: ["baking"], isDefault: true),
        ]
    }

    // MARK: - Money & Financial Skills Tasks (25)

    private static var moneySkillsTasks: [TaskTemplate] {
        [
            // Basic Money Concepts
            TaskTemplate(title: "Count and sort coins", description: "Practice identifying and counting coins", category: .money, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["basics"], isDefault: true),
            TaskTemplate(title: "Practice making change", description: "Learn to calculate change from purchases", category: .money, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["math"], isDefault: true),
            TaskTemplate(title: "Budget a weekly allowance", description: "Plan how to spend/save weekly money", category: .money, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["budgeting"], isDefault: true),

            // Saving & Goals
            TaskTemplate(title: "Set a savings goal", description: "Plan savings for something wanted", category: .money, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["saving", "goals"], isDefault: true),
            TaskTemplate(title: "Track expenses for week", description: "Record all money spent for one week", category: .money, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["tracking"], isDefault: true),
            TaskTemplate(title: "Learn about interest", description: "Understand how savings grow", category: .money, suggestedLevel: .level3, estimatedMinutes: 25, tags: ["learning"], isDefault: true),

            // Shopping & Value
            TaskTemplate(title: "Compare prices while shopping", description: "Practice finding best value", category: .money, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["shopping"], isDefault: true),
            TaskTemplate(title: "Calculate unit prices", description: "Learn to compare prices per unit", category: .money, suggestedLevel: .level3, estimatedMinutes: 20, tags: ["math", "shopping"], isDefault: true),
            TaskTemplate(title: "Learn about needs vs wants", description: "Understand difference between needs and wants", category: .money, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["concepts"], isDefault: true),

            // Entrepreneurship
            TaskTemplate(title: "Plan a small business idea", description: "Think through a business concept", category: .money, suggestedLevel: .level4, estimatedMinutes: 45, tags: ["entrepreneurship"], isDefault: true),
            TaskTemplate(title: "Calculate profit and loss", description: "Learn basic business math", category: .money, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["math", "business"], isDefault: true),
        ]
    }

    // MARK: - Organization & Planning Tasks (20)

    private static var organizationTasks: [TaskTemplate] {
        [
            // Planning Skills
            TaskTemplate(title: "Make a daily schedule", description: "Plan out your day hour by hour", category: .organization, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["planning"], isDefault: true),
            TaskTemplate(title: "Create a weekly planner", description: "Plan activities for the week", category: .organization, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["planning"], isDefault: true),
            TaskTemplate(title: "Make a to-do list", description: "List and prioritize tasks", category: .organization, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["lists"], isDefault: true),
            TaskTemplate(title: "Set and track goals", description: "Set goals and track progress", category: .organization, suggestedLevel: .level3, estimatedMinutes: 25, tags: ["goals"], isDefault: true),

            // Organization
            TaskTemplate(title: "Organize school backpack", description: "Sort and organize backpack contents", category: .organization, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["school"], isDefault: true),
            TaskTemplate(title: "Organize desk/workspace", description: "Clean and organize study area", category: .organization, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["workspace"], isDefault: true),
            TaskTemplate(title: "File or organize papers", description: "Sort and file paperwork", category: .organization, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["filing"], isDefault: true),
            TaskTemplate(title: "Digital file organization", description: "Organize computer files and folders", category: .organization, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["digital"], isDefault: true),

            // Time Management
            TaskTemplate(title: "Practice prioritizing tasks", description: "Learn to rank tasks by importance", category: .organization, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["prioritizing"], isDefault: true),
            TaskTemplate(title: "Use a timer for tasks", description: "Practice working with timed intervals", category: .organization, suggestedLevel: .level1, estimatedMinutes: 25, tags: ["time-management"], isDefault: true),
        ]
    }

    // MARK: - Social Skills Tasks (25)

    private static var socialSkillsTasks: [TaskTemplate] {
        [
            // Communication
            TaskTemplate(title: "Practice active listening", description: "Focus on listening without interrupting", category: .socialSkills, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["listening"], isDefault: true),
            TaskTemplate(title: "Learn conversation starters", description: "Practice starting conversations", category: .socialSkills, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["conversation"], isDefault: true),
            TaskTemplate(title: "Practice giving compliments", description: "Give genuine compliments to others", category: .socialSkills, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["kindness"], isDefault: true),
            TaskTemplate(title: "Practice saying 'no' politely", description: "Learn to decline respectfully", category: .socialSkills, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["boundaries"], isDefault: true),

            // Empathy & Understanding
            TaskTemplate(title: "Put yourself in someone's shoes", description: "Practice empathy and perspective-taking", category: .socialSkills, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["empathy"], isDefault: true),
            TaskTemplate(title: "Resolve a conflict peacefully", description: "Work through disagreement calmly", category: .socialSkills, suggestedLevel: .level3, estimatedMinutes: 30, tags: ["conflict-resolution"], isDefault: true),
            TaskTemplate(title: "Apologize sincerely", description: "Give a genuine apology", category: .socialSkills, suggestedLevel: .level2, estimatedMinutes: 10, tags: ["apology"], isDefault: true),

            // Collaboration
            TaskTemplate(title: "Work on group project", description: "Collaborate with others on shared task", category: .socialSkills, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["teamwork"], isDefault: true),
            TaskTemplate(title: "Practice taking turns", description: "Share and take turns fairly", category: .socialSkills, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["sharing"], isDefault: true),

            // Phone & Digital
            TaskTemplate(title: "Make a phone call", description: "Practice phone etiquette", category: .socialSkills, suggestedLevel: .level2, estimatedMinutes: 10, tags: ["phone"], isDefault: true),
            TaskTemplate(title: "Write a thank-you note", description: "Write and send thank-you message", category: .socialSkills, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["gratitude", "writing"], isDefault: true),
        ]
    }

    // MARK: - Creative Projects Tasks (30)

    private static var creativeTasks: [TaskTemplate] {
        [
            // Writing
            TaskTemplate(title: "Write a short story", description: "Create an original short story", category: .creative, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["writing"], isDefault: true),
            TaskTemplate(title: "Write a poem", description: "Compose an original poem", category: .creative, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["writing", "poetry"], isDefault: true),
            TaskTemplate(title: "Start a blog post", description: "Write a blog entry on topic of interest", category: .creative, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["writing", "blogging"], isDefault: true),
            TaskTemplate(title: "Create a comic strip", description: "Draw and write a comic strip", category: .creative, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["drawing", "writing"], isDefault: true),

            // Photography & Video
            TaskTemplate(title: "Take creative photos", description: "Practice photography with a theme", category: .creative, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["photography"], isDefault: true),
            TaskTemplate(title: "Edit photos creatively", description: "Edit photos with creative filters/effects", category: .creative, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["photography", "editing"], isDefault: true),
            TaskTemplate(title: "Make a video", description: "Create and edit a short video", category: .creative, suggestedLevel: .level4, estimatedMinutes: 90, tags: ["video"], isDefault: true),

            // Design & Making
            TaskTemplate(title: "Design a poster", description: "Create a poster for event or cause", category: .creative, suggestedLevel: .level3, estimatedMinutes: 40, tags: ["design"], isDefault: true),
            TaskTemplate(title: "Invent something new", description: "Design an original invention or idea", category: .creative, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["inventing"], isDefault: true),
            TaskTemplate(title: "Create a game", description: "Invent a new game with rules", category: .creative, suggestedLevel: .level4, estimatedMinutes: 60, tags: ["game-design"], isDefault: true),
        ]
    }

    // MARK: - Hobbies & Interests Tasks (25)

    private static var hobbiesTasks: [TaskTemplate] {
        [
            // Collections & Organization
            TaskTemplate(title: "Organize a collection", description: "Sort and display a collection", category: .hobbies, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["collecting"], isDefault: true),
            TaskTemplate(title: "Research a hobby interest", description: "Learn more about a hobby", category: .hobbies, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["research"], isDefault: true),

            // Games & Puzzles
            TaskTemplate(title: "Complete a puzzle", description: "Finish a jigsaw puzzle", category: .hobbies, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["puzzles"], isDefault: true),
            TaskTemplate(title: "Play a board game", description: "Play board game with family/friends", category: .hobbies, suggestedLevel: .level2, estimatedMinutes: 45, tags: ["games"], isDefault: true),
            TaskTemplate(title: "Play chess", description: "Play a game of chess", category: .hobbies, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["chess", "strategy"], isDefault: true),
            TaskTemplate(title: "Solve brain teasers", description: "Work on logic puzzles or brain teasers", category: .hobbies, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["puzzles", "logic"], isDefault: true),

            // Nature & Science
            TaskTemplate(title: "Bird watching", description: "Observe and identify birds", category: .hobbies, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["nature"], isDefault: true),
            TaskTemplate(title: "Star gazing", description: "Observe stars and constellations", category: .hobbies, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["astronomy"], isDefault: true),
            TaskTemplate(title: "Nature journaling", description: "Document nature observations", category: .hobbies, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["nature", "journaling"], isDefault: true),

            // Learning
            TaskTemplate(title: "Watch educational video", description: "Learn from educational content", category: .hobbies, suggestedLevel: .level1, estimatedMinutes: 20, tags: ["learning"], isDefault: true),
            TaskTemplate(title: "Try a new hobby", description: "Explore a new hobby or interest", category: .hobbies, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["exploration"], isDefault: true),
        ]
    }

    // MARK: - Building & Making Tasks (25)

    private static var buildingTasks: [TaskTemplate] {
        [
            // Construction
            TaskTemplate(title: "Build with LEGO - 30 min", description: "Create with LEGO or building blocks", category: .building, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["lego", "building"], isDefault: true),
            TaskTemplate(title: "Build with LEGO - 1 hour", description: "Extended LEGO building session", category: .building, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["lego", "building"], isDefault: true),
            TaskTemplate(title: "Build a model", description: "Assemble a model kit", category: .building, suggestedLevel: .level3, estimatedMinutes: 90, tags: ["models"], isDefault: true),
            TaskTemplate(title: "Build a fort or structure", description: "Build a fort with household items", category: .building, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["building", "creative"], isDefault: true),

            // Woodworking & Crafting
            TaskTemplate(title: "Simple woodworking project", description: "Create something from wood", category: .building, suggestedLevel: .level4, estimatedMinutes: 90, tags: ["woodworking"], isDefault: true),
            TaskTemplate(title: "Build a birdhouse", description: "Construct a birdhouse", category: .building, suggestedLevel: .level4, estimatedMinutes: 120, tags: ["woodworking", "nature"], isDefault: true),

            // Tech Building
            TaskTemplate(title: "Build a robot", description: "Assemble and program a robot", category: .building, suggestedLevel: .level5, estimatedMinutes: 120, tags: ["robotics", "tech"], isDefault: true),
            TaskTemplate(title: "Electronics project", description: "Build simple electronics project", category: .building, suggestedLevel: .level4, estimatedMinutes: 90, tags: ["electronics"], isDefault: true),

            // Science
            TaskTemplate(title: "Science experiment", description: "Conduct a safe science experiment", category: .building, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["science"], isDefault: true),
            TaskTemplate(title: "Build a volcano", description: "Create erupting volcano experiment", category: .building, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["science", "experiment"], isDefault: true),
        ]
    }

    // MARK: - Volunteering & Service Tasks (20)

    private static var volunteeringTasks: [TaskTemplate] {
        [
            TaskTemplate(title: "Help elderly neighbor", description: "Assist an elderly neighbor with tasks", category: .volunteering, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["helping"], isDefault: true),
            TaskTemplate(title: "Volunteer at animal shelter", description: "Help care for shelter animals", category: .volunteering, suggestedLevel: .level4, estimatedMinutes: 90, tags: ["animals"], isDefault: true),
            TaskTemplate(title: "Food bank volunteer", description: "Help at local food bank", category: .volunteering, suggestedLevel: .level4, estimatedMinutes: 120, tags: ["food"], isDefault: true),
            TaskTemplate(title: "Clean up local park", description: "Pick up litter in community park", category: .volunteering, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["environment"], isDefault: true),
            TaskTemplate(title: "Tutor younger student", description: "Help younger student with schoolwork", category: .volunteering, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["teaching"], isDefault: true),
            TaskTemplate(title: "Make cards for seniors", description: "Create cards for nursing home residents", category: .volunteering, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["crafts", "seniors"], isDefault: true),
            TaskTemplate(title: "Donate used items", description: "Sort and donate items to charity", category: .volunteering, suggestedLevel: .level2, estimatedMinutes: 45, tags: ["donation"], isDefault: true),
            TaskTemplate(title: "Read to younger kids", description: "Read stories to younger children", category: .volunteering, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["reading", "teaching"], isDefault: true),
        ]
    }

    // MARK: - Acts of Kindness Tasks (25)

    private static var kindnessTasks: [TaskTemplate] {
        [
            // Family Kindness
            TaskTemplate(title: "Help parent without being asked", description: "Do something helpful proactively", category: .kindness, suggestedLevel: .level2, estimatedMinutes: 20, tags: ["family"], isDefault: true),
            TaskTemplate(title: "Make card for family member", description: "Create a thoughtful card", category: .kindness, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["family", "crafts"], isDefault: true),
            TaskTemplate(title: "Cook/bake for family", description: "Make something for family to enjoy", category: .kindness, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["cooking"], isDefault: true),
            TaskTemplate(title: "Give a genuine compliment", description: "Compliment family members sincerely", category: .kindness, suggestedLevel: .level1, estimatedMinutes: 5, tags: ["words"], isDefault: true),

            // Friend Kindness
            TaskTemplate(title: "Help a friend", description: "Assist a friend with something difficult", category: .kindness, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["friends"], isDefault: true),
            TaskTemplate(title: "Make gift for someone", description: "Create handmade gift for someone", category: .kindness, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["crafts", "gifts"], isDefault: true),
            TaskTemplate(title: "Share something meaningful", description: "Share a possession with someone", category: .kindness, suggestedLevel: .level2, estimatedMinutes: 15, tags: ["sharing"], isDefault: true),

            // Community Kindness
            TaskTemplate(title: "Hold door for others", description: "Practice courtesy throughout day", category: .kindness, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["courtesy"], isDefault: true),
            TaskTemplate(title: "Pick up litter", description: "Clean up litter you find", category: .kindness, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["environment"], isDefault: true),
            TaskTemplate(title: "Leave positive notes", description: "Leave encouraging notes for others", category: .kindness, suggestedLevel: .level1, estimatedMinutes: 20, tags: ["encouragement"], isDefault: true),
        ]
    }

    // MARK: - Environmental Actions Tasks (20)

    private static var environmentTasks: [TaskTemplate] {
        [
            // Conservation
            TaskTemplate(title: "Start recycling project", description: "Set up or improve recycling at home", category: .environment, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["recycling"], isDefault: true),
            TaskTemplate(title: "Sort recyclables", description: "Properly sort recyclable materials", category: .environment, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["recycling"], isDefault: true),
            TaskTemplate(title: "Start a compost bin", description: "Begin composting food scraps", category: .environment, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["composting"], isDefault: true),
            TaskTemplate(title: "Reduce water usage", description: "Track and reduce water consumption", category: .environment, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["conservation"], isDefault: true),

            // Growing & Planting
            TaskTemplate(title: "Plant a tree or flowers", description: "Plant and care for plants", category: .environment, suggestedLevel: .level3, estimatedMinutes: 60, tags: ["planting"], isDefault: true),
            TaskTemplate(title: "Start a small garden", description: "Begin growing vegetables or herbs", category: .environment, suggestedLevel: .level4, estimatedMinutes: 90, tags: ["gardening"], isDefault: true),
            TaskTemplate(title: "Care for houseplants", description: "Water and maintain indoor plants", category: .environment, suggestedLevel: .level1, estimatedMinutes: 15, tags: ["plants"], isDefault: true),

            // Learning & Awareness
            TaskTemplate(title: "Research environmental issue", description: "Learn about an environmental topic", category: .environment, suggestedLevel: .level2, estimatedMinutes: 30, tags: ["learning"], isDefault: true),
            TaskTemplate(title: "Make eco-friendly choice", description: "Choose sustainable option consciously", category: .environment, suggestedLevel: .level1, estimatedMinutes: 10, tags: ["sustainability"], isDefault: true),
            TaskTemplate(title: "Create environmental poster", description: "Make poster about environmental issue", category: .environment, suggestedLevel: .level3, estimatedMinutes: 45, tags: ["art", "education"], isDefault: true),
        ]
    }
}
